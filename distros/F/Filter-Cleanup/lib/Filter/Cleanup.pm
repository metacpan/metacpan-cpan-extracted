package Filter::Cleanup;

our $VERSION = '0.02';

use Carp;
use Filter::Util::Call;
use PPI;
use PPI::Document;
use PPI::Document::Fragment;

use constant READ_BYTES => 999_999;

sub import {
    my ($class, %args) = @_;
    my $debug = $args{debug} || 0;
    my $pad   = $args{pad}   || 0;
    
    my $self = bless {}, $class;
    $self->{dbg} = $debug;
    $self->{pad} = $pad;

    filter_add($self);
    return $self;
}

sub filter {
    my $self   = shift;
    my $status = filter_read(READ_BYTES);
    my $source = $_;

    $source = _transform($source);

    if ($self->{dbg} && $source ne $_) {
        my @lines = split /\n/, $_;
        if (@lines) {
            warn sprintf("\n=(%s) expansion\n", __PACKAGE__);

            for (my $i = $self->{pad}; $i <= ($self->{pad} +  $#lines); ++$i) {
                warn sprintf('%3d. %s', $i + 1, $lines[$i - $self->{pad}]), "\n";
            }

            warn "=cut\n\n";
        }
    }
    
    $_ = $source;
    return $status;
}

sub _transform {
    my $source = shift;
    my $pdom   = PPI::Document->new(\$source);

    my $wanted = sub {
       my ($node, $element) = @_;
       $element->isa('PPI::Token::Word') && $element->content eq 'cleanup';
    };

    if (my $cleanup = $pdom->find_first($wanted)) {
        # Get entire statement
        my $statement = $cleanup->statement;

        # Get code block
        my $block = $cleanup->snext_sibling;

        # Remove from tree
        $cleanup->remove(), $block->remove();

        # Collect rest of statement's lexical scope
        my @sibs;
        my $node = $statement;
        while (ref $node) {
            $node = $node->next_sibling;
            push @sibs, $node if $node;
        }

        # Remove rest of the scope from the tree
        foreach my $node (@sibs) {
            $node->remove();
        }

        # Generate code
        my $template = '{use Symbol;my($g,$e)=(gensym)x2;$g=eval{%s};$e=$@;%sif($e){use Carp;croak $e}else{$g}}';
        my $code = sprintf($template, join('', map {$_->content} @sibs), $block->content);

        # Replace $statement with new code
        my $fragment = PPI::Document::Fragment->new(\$code);

        foreach my $child ($fragment->children) {
            $statement->insert_before($child);
        }

        $statement->remove;
        return _transform($pdom->content);
    }

    return $pdom->content;
}

1;

__END__

=pod

=head1 NAME

Filter::Cleanup - A stackable way to deal with error handling

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Filter::Cleanup;
    use Filter::Cleanup debug => 1;

    sub foo {
        my $file_path = shift;
        open my $FH, $file_path or die $!;

        cleanup { close $FH };

        do_risky_stuff_with_fh($FH);
    }

    sub html {
        # cleanups stack and execute in reverse order
        cleanup { print "</html>" };
        cleanup { print "</body>" };

        print "<html>\n";
        print "<head><title>Test page</title></head>\n";
        print "<body>\n";

        print generate_page_body();
    }

=head1 DESCRIPTION

Filter::Cleanup provides a simple way to deal with cleaning up after multiple
error conditions modeled after the D programming language's C<scope(exit)>
mechanism.

Each C<cleanup> block operates in essentially the same manner as a C<finally>
block in languages supporting try/catch/finally style error handling.

C<cleanup> blocks may be placed anywhere in a scope. All statements lexically
scoped after the C<cleanup> block will be wrapped in an C<eval>. Should an error
be triggered within the block, the C<cleanup> statement will be called before
any error is rethrown (using C<croak>).

Within the C<cleanup> block, the status of C<$@> may be inspected normally.

Multiple C<cleanup> blocks stack, and each I<MUST> be followed by a semi-colon
to ensure proper organization of the outputted code. C<cleanup>s are executed
in reverse order (it's a stack, see?) and may be nested, although this defeats
the purpose. The reason for reverse execution is that each cleanup represents
another nested level of evals and clean-up code.

Take the following code:

    use Filter::Cleanup;
    
    sub example {
        cleanup { print "FOO" };
        print "BAR";
        return 1;
    }

This is roughly the output of the source filter:

    sub example {
        my $result = eval {
            print "BAR";
            return 1;
        };
        
        my $error = $@;
        
        print "FOO";
        
        if ($error) {
            croak $error;
        } else {
            $result; # returns 1
        }
    }

Now with multiple cleanups:

    use Filter::Cleanup;
    
    sub example {
        cleanup { print "FOO" };
        cleanup { print "BAZ" };
        print "BAR";
        return 1;
    }
    
The following code would be generated:

    sub example {
        my $result = eval {
            my $result = eval {
                print "BAR";
                return 1;
            };
            
            my $error = $@;
            
            print "BAZ";
            
            if ($error) {
                croak $error;
            } else {
                $result;
            }
        };
        
        my $error = $@;
        
        print "FOO";
        
        if ($error) {
            croak $error;
        } else {
            $result; # returns 1
        }
    }

Internally, PPI is used to parse the module and generate the new code. This is
because there are so many different forms which could proceed a C<cleanup> block
that there is no more efficient way to ensure that valid code is emitted. PPI
has proven to be stable, robust, and very reasonably efficient.

=head2 Modifying return variables within a cleanup block

This can sometimes have surprising results due to the manner in which C<cleanup>
blocks are evaluated. By the time the C<cleanup> block executes, the result of
evaluating the protected code has already been determined and stored. C<Cleanup>
blocks are then processed, and their results are discarded after being inspected
for errors. Therefore, something like this:

    sub test {
        my @words = ('foo');
        
        cleanup { push @words, 'bat' };
        cleanup { push @words, 'baz' };
        cleanup { push @words, 'bar' };
        
        return @words;
    }

...will cause 'foo' to be returned, because @words has not been modified by the
time the return value is calculated.

In order to effect changes in return values in cleanup (a questionable
practice, but hey, I don't judge), a reference is required:

    sub test {
        my $words = ['foo'];
        
        cleanup { push @$words, 'bat' };
        cleanup { push @$words, 'baz' };
        cleanup { push @$words, 'bar' };
        
        return $words;
    }
    
The above code will return C<['foo', 'bar', 'baz', 'bat']>.

=head1 SUBROUTINES

=over

=item import

Importing Filter::Cleanup makes the C<cleanup> keyword available in the
importing scope. Adding C<debug=>1> will cause the generated code to be
printed to C<STDERR> with line numbers.

=item filter

Expected by Filter::Util::Call; provides the entry point into the source filter.

=item _transform

Performs the actual work of modifying the source.

=back

=head1 AUTHOR

Jeff Ober L<mailto:jeffober@gmail.com>

=head1 LICENSE

BSD license

=cut
