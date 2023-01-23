package LaTeX::Pod;

use strict;
use warnings;
use boolean qw(true false);
use constant do_exec => 1;
use constant no_exec => 0;

use Carp qw(croak);
use LaTeX::TOM ();
use List::MoreUtils qw(any);
use Params::Validate ':all';

our ($VERSION, $DEBUG);

$VERSION = '0.22';
$DEBUG   = false;

validation_options(
    on_fail => sub
{
    my ($error) = @_;
    chomp $error;
    croak $error;
},
    stack_skip => 2,
);

my $regex_list_type = join '|', qw(description enumerate itemize);
my @text_node_types = qw(text tag);

sub new
{
    my $class = shift;

    my $self = bless {}, ref($class) || $class;

    $self->_init_check(@_);
    $self->_init(@_);

    return $self;
}

sub convert
{
    my $self = shift;

    $self->_init_check($self->{file});
    $self->_init_vars;

    my $nodes = $self->_init_tom;

    my $sort = sub { my $order = pop; sort { $order->{$a} <=> $order->{$b} } keys %{$_[0]} };

    my ($command_keyword, @queue);

    foreach my $i (0 .. $#$nodes) {
        my $node = $nodes->[$i];
        my $type = $node->getNodeType;

        if ($type eq 'TEXT') {
            next if $node->getNodeText !~ /\w+/
                 or $node->getNodeText =~ /^\\\w+$/m;

            if ($node->getNodeText =~ /\\item/) {
                push @queue, [ sub { shift->_process_text_item(@_) }, $node ];
            }
            elsif (!defined $command_keyword && ($i >= 1
                 ? !$self->_is_environment_type($node->getParent, 'verbatim') : true)
            ) {
                push @queue, [ sub { shift->_process_text(@_) }, $node ];
            }
            elsif (defined $command_keyword) {
                push @queue, [ $self->{dispatch_text}->{$command_keyword}, $node ];
                undef $command_keyword;
            }
        }
        elsif ($type eq 'COMMENT') {
            push @queue, [ sub { shift->_process_comment(@_) }, $node ];
        }
        elsif ($type eq 'ENVIRONMENT') {
            my $class = $node->getEnvironmentClass;
            if ($class eq 'abstract') {
                next;
            }
            elsif ($class =~ /^($regex_list_type)$/) {
                push @queue, [ sub { shift->_process_start_item(@_) }, $node, $1 ];
            }
            elsif ($class eq 'verbatim') {
                push @queue, [ sub { shift->_process_text_verbatim(@_) }, $node->getFirstChild ];
            }
        }
        elsif ($type eq 'COMMAND') {
            my $cmd_name = $node->getCommandName;
            foreach my $keyword ($sort->(map $self->{$_}, qw(command_checks command_order))) {
                if ($self->{command_checks}->{$keyword}->($cmd_name)) {
                    my ($code, $exec) = @{$self->{dispatch_command}->{$keyword}};
                    if (defined $exec && $exec) {
                        $code->($self);
                    }
                    else {
                        push @queue, [ $code, $node ] if defined $exec;
                        $command_keyword = $keyword;
                    }
                    last;
                }
            }
        }
    }

    foreach my $dispatch (@queue) {
        my ($code, $node, @args) = @$dispatch;
        $code->($self, $node, @args);
    }
    $self->_process_end;

    return $self->_pod_finalize;
}

sub _init_check
{
    my $self = shift;

    validate_pos(@_, { type => SCALAR });

    my ($file) = @_;
    my $error = sub
    {
        return 'does not exist' unless -e shift;
        return 'is not a file'  unless -f _;
        return 'is empty'       unless -s _;
        return                            undef;

    }->($file);

    defined $error and croak "Cannot open `$file': $error";
}

sub _init
{
    my $self = shift;
    my ($file) = @_;

    $self->{file} = $file;

    my $i = 0;
    %{$self->{command_order}} = map { $_ => $i++ } qw(directive title author chapter section subsection textbf textsf emph);

    %{$self->{command_checks}} = (
        directive  => sub { $_[0] =~ /^(?:documentclass|usepackage|pagestyle)$/ },
        title      => sub { $_[0] eq 'title'                                    },
        author     => sub { $_[0] eq 'author'                                   },
        chapter    => sub { $_[0] eq 'chapter'                                  },
        section    => sub { $_[0] eq 'section'                                  },
        subsection => sub { $_[0] =~ /^(?:sub){1,2}section$/                    },
        textbf     => sub { $_[0] eq 'textbf'                                   },
        textsf     => sub { $_[0] eq 'textsf'                                   },
        emph       => sub { $_[0] eq 'emph'                                     },
    );
    %{$self->{dispatch_command}} = (
        directive  => [ sub {},                                 undef   ],
        title      => [ sub {},                                 undef   ],
        author     => [ sub {},                                 undef   ],
        chapter    => [ sub { shift->_process_chapter(@_)    }, no_exec ],
        section    => [ sub { shift->_process_section(@_)    }, no_exec ],
        subsection => [ sub { shift->_process_subsection(@_) }, no_exec ],
        textbf     => [ sub {},                                 undef   ],
        textsf     => [ sub {},                                 undef   ],
        emph       => [ sub {},                                 undef   ],
    );
    %{$self->{dispatch_text}} = (
        directive  => sub { shift->_process_directive(shift, 'directive') },
        title      => sub { shift->_process_directive(shift, 'title')     },
        author     => sub { shift->_process_directive(shift, 'author')    },
        chapter    => sub { shift->_process_text_title(@_)                },
        section    => sub { shift->_process_text_title(@_)                },
        subsection => sub { shift->_process_text_title(@_)                },
        textbf     => sub { shift->_process_tag(shift, 'textbf')          },
        textsf     => sub { shift->_process_tag(shift, 'textsf')          },
        emph       => sub { shift->_process_tag(shift, 'emph')            },
    );
}

sub _init_vars
{
    my $self = shift;

    delete @$self{qw(list node previous)};

    $self->{pod} = [];

    %{$self->{title_inc}} = (
        title   => 1,
        chapter => 1,
    );
}

sub _init_tom
{
    my $self = shift;

    my $parser   = LaTeX::TOM->new(2); # silently discard warnings about unparseable LaTeX
    my $document = $parser->parseFile($self->{file});
    my $nodes    = $document->getAllNodes;

    return $nodes;
}

sub _process_directive
{
    my $self = shift;
    my ($node, $directive) = @_;

    return if any { $directive eq $_ } qw(directive author);

    if ($directive eq 'title') {
        $self->_pod_add('=head' . "$self->{title_inc}{title} " . $node->getNodeText);
    }
}

sub _process_comment
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    my $text = $node->getNodeText;

    $self->_scrub_newlines(\$text);

    $text =~ s/^ \s*? \% \s*? (?=\S)//x;

    $self->_pod_add("=for comment $text");
}

sub _process_text_title
{
    my $self = shift;
    my ($node) = @_;

    my $text = $node->getNodeText;

    $self->_process_spec_chars(\$text);

    $self->_pod_append($text);
}

sub _process_text_verbatim
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    my $text = $node->getNodeText;

    $self->_scrub_newlines(\$text);
    $self->_process_spec_chars(\$text);
    $self->_prepend_spaces(\$text);

    $self->_pod_add($text);
}

sub _process_start_item
{
    my $self = shift;
    my ($node, $type) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    my $nested = $self->_list_nestedness($node);

    if ($nested) {
        $self->_pod_add('=back');
    }

    %{$self->{list}{$nested}} = (
        type => $type,
        enum => 1,
    );

    $self->_pod_add('=over ' . (4 + $nested));

    $self->_register_previous('list');
}

sub _process_text_item
{
    my $self = shift;
    my ($node) = @_;

    $self->_unregister_previous(@text_node_types);

    my $nested = $self->_list_nestedness($node) - 1;

    if ($self->_is_environment_type($node->getPreviousSibling, qr/^(?:$regex_list_type)$/)) {
        $self->_pod_add('=back');
        $self->_pod_add('=over ' . (4 + $nested));
    }

    my $text = $node->getNodeText;

    my $type =  $self->{list}{$nested}{type};
    my $enum = \$self->{list}{$nested}{enum};

    LOOP: {
        local ($1, $2);
        if ($text =~ /\G \s*? \\item (?:\s*?\[(.+?)\]\s+?|\s+?) (\S.+)?$/cgmx) {
            my $pod = '=item ';
            if ($type eq 'description') {
                $pod .= defined $1 ? "B<$1> " : '';
            }
            elsif ($type eq 'enumerate') {
                $pod .= defined $1 ? "$1 " : ($$enum++ . '. ');
            }
            elsif ($type eq 'itemize') {
                $pod .= defined $1 ? "$1 " : '* ';
            }
            $pod .= defined $2 ? $2 : '';
            $self->_process_spec_chars(\$pod);
            $self->_pod_add($pod);
            redo;
        }
        elsif ($text =~ /\G \s*? (\S.+?) \s*? (?:(?=\\item)|\z)/gsx) {
            my $pod = $1;
            $self->_process_spec_chars(\$pod);
            $self->_pod_add($pod);
            redo;
        }
    }
}

sub _process_end_item
{
    my $self = shift;
    my ($node) = @_;

    return unless $self->_is_set_previous('list');

    my $parent = $node->getParent;

    $parent = $parent->getParent if $self->_is_environment_type($parent, 'verbatim');

    if ($self->_is_environment_type($parent, 'document')) {
        $self->_pod_add('=back');
        $self->_unregister_previous('list', @text_node_types);
    }
}

sub _process_text
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    if ($self->_is_environment_type($node->getPreviousSibling, 'abstract')) {
        $self->_unregister_previous(@text_node_types);
    }

    my $text = $node->getNodeText;

    $self->_scrub_newlines(\$text);
    $self->_process_spec_chars(\$text);

    $self->_text_setter($text);

    $self->_register_previous('text');
}

sub _process_chapter
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    $self->{title_inc}{section} ||= $self->{title_inc}{chapter} + 1;

    $self->_pod_add('=head' . $self->{title_inc}{chapter} . ' ');
}

sub _process_section
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    $self->{title_inc}{section} ||= 1;

    $self->_pod_add('=head' . "$self->{title_inc}{section} ");
}

sub _process_subsection
{
    my $self = shift;
    my ($node) = @_;

    $self->_process_end_item($node);

    $self->_unregister_previous(@text_node_types);

    my $cmd_name = $node->getCommandName;

    my $nested = 0;
    $nested++ while $cmd_name =~ /\Gsub/g;

    $self->_pod_add('=head' . ($self->{title_inc}{section} + $nested) . ' ');
}

sub _process_spec_chars
{
    my $self = shift;
    my ($text) = @_;

    my %umlauts = (a => 'ä',
                   A => 'Ä',
                   u => 'ü',
                   U => 'Ü',
                   o => 'ö',
                   O => 'Ö');

    while (my ($from, $to) = each %umlauts) {
        $$text =~ s/\\\"$from/$to/g;
    }

    foreach my $escape ('#', qw($ % & _ { })) {
        $$text =~ s/\\\Q$escape\E/$escape/g;
    }

    $$text =~ s/\\ldots/.../g;

    $$text =~ s/\\verb\*?(.)(.+?)\1/C<$2>/g;
    $$text =~ s/(?:\\\\|\\newline)/\n/g;
}

sub _process_tag
{
    my $self = shift;
    my ($node, $tag) = @_;

    $self->_process_end_item($node);

    if ($self->_is_environment_type($node->getPreviousSibling, 'abstract')) {
        $self->_unregister_previous(@text_node_types);
    }

    my $text = $node->getNodeText;

    my %tags = (textbf => 'B',
                textsf => 'C',
                emph   => 'I');

    $self->_text_setter("$tags{$tag}<$text>");

    $self->_register_previous('tag');
}

sub _process_end
{
    my $self = shift;

    if ($self->_is_set_previous('list')) {
        $self->_pod_add('=back');
        $self->_unregister_previous('list');
    }
}

sub _is_environment_type
{
    my $self = shift;
    my ($node, $type) = @_;

    $type = qr/^$type$/ unless ref $type eq 'REGEXP';

    return ($node
         && $node->getNodeType eq 'ENVIRONMENT'
         && $node->getEnvironmentClass =~ $type);
}

sub _list_nestedness
{
    my $self = shift;
    my ($node) = @_;

    my $nested = 0;

    for (my $parent = $node->getParent;
        $self->_is_environment_type($parent, qr/^(?:$regex_list_type)$/);
        $parent = $parent->getParent
    ) {
        $nested++;
    }

    return $nested;
}

sub _prepend_spaces
{
    my $self = shift;
    my ($text) = @_;

    unless (length $$text) {
        $$text =~ s/^/ /;
        return;
    }

    $$text =~ s/^/ /gm;
}

sub _text_setter
{
    my $self = shift;
    my ($text) = @_;

    my $append = any { $self->_is_set_previous($_) } ('list', @text_node_types);
    my $setter = $append ? '_pod_append' : '_pod_add';

    $self->$setter($text);
}

sub _pod_add
{
    my $self = shift;
    my ($pod) = @_;

    if (@{$self->{pod}}) {
        $self->{pod}->[-1] =~ s/[\ \t]+$//gm;
    }

    push @{$self->{pod}}, $pod;

    $self->_debug($pod) if $DEBUG;
}

sub _pod_append
{
    my $self = shift;
    my ($pod) = @_;

    $self->{pod}->[-1] .= $pod;

    $self->_debug($pod) if $DEBUG;
}

sub _debug
{
    my $self = shift;
    my ($pod) = @_;

    my $re = qr/^.+::(.+)$/;

    my $frame = (caller(2))[3] =~ /^.+::_text_setter$/ ? 1 : 0;

    my ($sub)    = (caller(2 + $frame))[3] =~ $re;
    my  $line    = (caller(1 + $frame))[2];
    my ($setter) = (caller(1 + $frame))[3] =~ $re;

    my $index = @{$self->{pod}} - 1;

    printf STDERR ("%-12s(%-25s:%03d):[%3d]\t'%s'\n", $setter, $sub, $line, $index, $pod);
}

sub _scrub_newlines
{
    my $self = shift;
    my ($text) = @_;

    $$text =~ s/^\n+//;
    $$text =~ s/\n+$//;
}

sub _pod_get
{
    my $self = shift;

    return $self->{pod};
}

sub _pod_finalize
{
    my $self = shift;

    $self->_pod_add("=cut\n");

    return join "\n\n", @{$self->_pod_get};
}

sub _register_node
{
    my $self = shift;
    my ($item) = @_;

    $self->{node}{$item} = true;
}

sub _is_set_node
{
    my $self = shift;
    my ($item) = @_;

    return $self->{node}{$item} ? true : false;
}

sub _unregister_node
{
    my $self = shift;
    my ($item) = @_;

    delete $self->{node}{$item};
}

sub _register_previous
{
    my $self = shift;
    my ($item) = @_;

    $self->{previous}{$item} = true;
}

sub _is_set_previous
{
    my $self = shift;
    my @items = @_;

    my $ok = eval true; # eval in order to avoid fatal errors on some older perls

    foreach my $item (@items) {
        $ok &= $self->{previous}{$item} ? true : false;
    }

    return $ok;
}

sub _unregister_previous
{
    my $self = shift;
    my @items = @_;

    foreach my $item (@items) {
        delete $self->{previous}{$item};
    }
}

=head1 NAME

LaTeX::Pod - Transform LaTeX source files to POD (Plain old documentation)

=head1 SYNOPSIS

 use LaTeX::Pod;

 $parser = LaTeX::Pod->new('/path/to/source');
 print $parser->convert;

=head1 DESCRIPTION

C<LaTeX::Pod> converts LaTeX sources to Perl's POD (Plain old documentation).
Currently only a subset of the available LaTeX language is supported;
see L<SUPPORTED LANGUAGE SUBSET> for further details.

=head1 CONSTRUCTOR

=head2 new

The constructor requires that the path to the LaTeX source is defined:

 $parser = LaTeX::Pod->new('/path/to/source');

Returns the parser object.

=head1 METHODS

=head2 convert

There is one public I<method> available, namely C<convert()>:

 $pod = $parser->convert;

Returns the computed POD as a string.

=head1 SUPPORTED LANGUAGE SUBSET

LaTeX currently supported:

=over 4

=item * abstracts

=item * chapters

=item * sections/subsections/subsubsections

=item * description, enumerate and itemize lists

=item * verbatim blocks (and indentation)

=item * plain text

=item * bold/italic/code font tags

=item * umlauts

=item * newlines

=item * comments

=back

=head1 IMPLEMENTATION DETAILS

The current implementation is based upon L<LaTeX::TOM> (the framework being
used for parsing the LaTeX source) and its clear distinction between various
types of nodes. As an example, a C<\chapter> command has a separate text
associated with it as its content. C<LaTeX::Pod> uses a "look-behind" mechanism
for commands and their corresponding texts since they currently cannot be easily
detected without such a mechanism.

Thus C<LaTeX::Pod> was designed with the intention to be I<context-sensitive>
aware. This is also being aimed at by eventually registering which type of node
has been seen before the current one -- useful when constructing logical paragraphs
made out of two or more nodes. C<LaTeX::Pod> then finally unregisters the type
of node seen when it is no longer required. In addition, a dispatch queue is built
internally which is executed after all nodes have been processed.

Considering that the POD format has a limited subset of directives, the complexity
of keeping track of node occurences appears to be bearable. Leading and trailing
newlines will be removed from the node's text extracted where needed; furthermore,
trailing spaces and tabs will also be purged from each line of POD resulting.

=head1 BUGS & CAVEATS

It is highly recommended to ensure that the structure of the LaTeX input file
follows the format specification strictly or the parser may B<not> succeed.

=head1 SEE ALSO

L<LaTeX::TOM>

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://dev.perl.org/licenses/>

=cut
