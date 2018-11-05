package HTML::Selector::XPath;

use strict;
use 5.008_001;
our $VERSION = '0.25';

require Exporter;
our @EXPORT_OK = qw(selector_to_xpath);
*import = \&Exporter::import;

use Carp;

sub selector_to_xpath {
    __PACKAGE__->new(shift)->to_xpath(@_);
}

# XXX: Identifiers should also allow any characters U+00A0 and higher, and any
# escaped characters.
my $ident = qr/(?![0-9]|-[-0-9])[-_a-zA-Z0-9]+/;

my $reg = {
    # tag name/id/class
    element => qr/^([#.]?)([^\s'"#.\/:@,=~>()\[\]|]*)((\|)([a-z0-9\\*_-]*))?/i,
    # attribute presence
    attr1   => qr/^\[ \s* ($ident) \s* \]/x,
    # attribute value match
    attr2   => qr/^\[ \s* ($ident) \s*
        ( [~|*^\$!]? = ) \s*
        (?: ($ident) | "([^"]*)" | '([^']*)') \s* \] /x,
    badattr => qr/^\[/,
    attrN   => qr/^:not\(/i, # we chop off the closing parenthesis below in the code
    pseudo  => qr/^:([()a-z0-9_+-]+)/i,
    # adjacency/direct descendance
    combinator => qr/^(\s*[>+~\s](?!,))/i,
    # rule separator
    comma => qr/^\s*,\s*/i,
};

sub new {
    my($class, $exp) = @_;
    bless { expression => $exp }, $class;
}

sub selector {
    my $self = shift;
    $self->{expression} = shift if @_;
    $self->{expression};
}

sub convert_attribute_match {
    my ($left,$op,$right) = @_;
    # negation (e.g. [input!="text"]) isn't implemented in CSS, but include it anyway:
    if ($op eq '!=') {
        "\@$left!='$right'";
    } elsif ($op eq '~=') { # substring attribute match
        "contains(concat(' ', \@$left, ' '), ' $right ')";
    } elsif ($op eq '*=') { # real substring attribute match
        "contains(\@$left, '$right')";
    } elsif ($op eq '|=') {
        "\@$left='$right' or starts-with(\@$left, '$right-')";
    } elsif ($op eq '^=') {
        "starts-with(\@$left,'$^N')";
    } elsif ($op eq '$=') {
        my $n = length($^N) - 1;
        "substring(\@$left,string-length(\@$left)-$n)='$^N'";
    } else { # exact match
        "\@$left='$^N'";
    }
}

sub _generate_child {
    my ($direction,$a,$b) = @_;
    if ($a == 0) { # 0n+b
        $b--;
        "[count($direction-sibling::*) = $b and parent::*]"
    } elsif ($a > 0) { # an + b
        return "[not((count($direction-sibling::*)+1)<$b) and ((count($direction-sibling::*) + 1) - $b) mod $a = 0 and parent::*]"
    } else { # -an + $b
        $a = -$a;
        return "[not((count($direction-sibling::*)+1)>$b) and (($b - (count($direction-sibling::*) + 1)) mod $a) = 0 and parent::*]"
    }
}

sub nth_child {
    my ($a,$b) = @_;
    if (@_ == 1) {
        ($a,$b) = (0,$a);
    }
    _generate_child('preceding', $a, $b);
}

sub nth_last_child {
    my ($a,$b) = @_;
    if (@_ == 1) {
        ($a,$b) = (0,$a);
    }
    _generate_child('following', $a, $b);
}

# A hacky recursive descent
# Only descends for :not(...)
sub consume {
    my ($self, $rule, %parms) = @_;
    my $root = $parms{root} || '/';

    return [$rule,''] if $rule =~ m!^/!; # If we start with a slash, we're already an XPath?!

    my @parts = ("$root/");
    my $last_rule = '';
    my @next_parts;

    my $wrote_tag;
    my $root_index = 0; # points to the current root
    # Loop through each "unit" of the rule
    while (length $rule && $rule ne $last_rule) {
        $last_rule = $rule;

        $rule =~ s/^\s*|\s*$//g;
        last unless length $rule;

        # Prepend explicit first selector if we have an implicit selector
        # (that is, if we start with a combinator)
        if ($rule =~ /$reg->{combinator}/) {
            $rule = "* $rule";
        }

        # Match elements
        if ($rule =~ s/$reg->{element}//) {
            my ($id_class,$name,$lang) = ($1,$2,$3);

            # to add *[1]/self:: for follow-sibling
            if (@next_parts) {
                push @parts, @next_parts; #, (pop @parts);
                @next_parts = ();
            }

            my $tag = $id_class eq '' ? $name || '*' : '*';
            
            if (defined $parms{prefix} and not $tag =~ /[*:|]/) {
                $tag = join ':', $parms{prefix}, $tag;
            }
            
            if (! $wrote_tag++) {
                push @parts, $tag;
            }

            # XXX Shouldn't the RE allow both, ID and class?
            if ($id_class eq '#') { # ID
                push @parts, "[\@id='$name']";
            } elsif ($id_class eq '.') { # class
                push @parts, "[contains(concat(' ', normalize-space(\@class), ' '), ' $name ')]";
            };
        };

        # Match attribute selectors
        if ($rule =~ s/$reg->{attr2}//) {
            push @parts, "[", convert_attribute_match( $1, $2, $^N ), "]";
        } elsif ($rule =~ s/$reg->{attr1}//) {
            # If we have no tag output yet, write the tag:
            if (! $wrote_tag++) {
                push @parts, '*';
            }
            push @parts, "[\@$1]";
        } elsif ($rule =~ $reg->{badattr}) {
            Carp::croak "Invalid attribute-value selector '$rule'";
        }

        # Match negation
        if ($rule =~ s/$reg->{attrN}//) {
            # Now we parse the rest, and after parsing the subexpression
            # has stopped, we must find a matching closing parenthesis:
            if ($rule =~ s/$reg->{attr2}//) {
                push @parts, "[not(", convert_attribute_match( $1, $2, $^N ), ")]";
            } elsif ($rule =~ s/$reg->{attr1}//) {
                push @parts, "[not(\@$1)]";
            } elsif ($rule =~ /$reg->{badattr}/) {
                Carp::croak "Invalid negated attribute-value selector ':not($rule)'";
            } else {
                my( $new_parts, $leftover ) = $self->consume( $rule, %parms );
                shift @$new_parts; # remove '//'
                my $xpath = join '', @$new_parts;
                
                push @parts, "[not(self::$xpath)]";
                $rule = $leftover;
            }
            $rule =~ s!^\s*\)!!
                or die "Unbalanced parentheses at '$rule'";
        }

        # Ignore pseudoclasses/pseudoelements
        while ($rule =~ s/$reg->{pseudo}//) {
            if ( my @expr = $self->parse_pseudo($1, \$rule) ) {
                push @parts, @expr;
            } elsif ( $1 eq 'disabled') {
                push @parts, '[@disabled]';
            } elsif ( $1 eq 'checked') {
                push @parts, '[@checked]';
            } elsif ( $1 eq 'selected') {
                push @parts, '[@selected]';
            } elsif ( $1 eq 'text') {
                push @parts, '*[@type="text"]';
            } elsif ( $1 eq 'first-child') {
                # Translates to :nth-child(1)
                push @parts, nth_child(1);
            } elsif ( $1 eq 'last-child') {
                push @parts, nth_last_child(1);
            } elsif ( $1 eq 'only-child') {
                push @parts, nth_child(1), nth_last_child(1);
            } elsif ($1 =~ /^lang\(([\w\-]+)\)$/) {
                push @parts, "[\@xml:lang='$1' or starts-with(\@xml:lang, '$1-')]";
            } elsif ($1 =~ /^nth-child\(odd\)$/) {
                push @parts, nth_child(2, 1);
            } elsif ($1 =~ /^nth-child\(even\)$/) {
                push @parts, nth_child(2, 0);
            } elsif ($1 =~ /^nth-child\((\d+)\)$/) {
                push @parts, nth_child($1);
            } elsif ($1 =~ /^nth-child\((\d+)n(?:\+(\d+))?\)$/) {
                push @parts, nth_child($1, $2||0);
            } elsif ($1 =~ /^nth-last-child\((\d+)\)$/) {
                push @parts, nth_last_child($1);
            } elsif ($1 =~ /^nth-last-child\((\d+)n(?:\+(\d+))?\)$/) {
                push @parts, nth_last_child($1, $2||0);
            } elsif ($1 =~ /^first-of-type$/) {
                push @parts, "[1]";
            } elsif ($1 =~ /^nth-of-type\((\d+)\)$/) {
                push @parts, "[$1]";
            } elsif ($1 =~ /^last-of-type$/) {
                push @parts, "[last()]";
            } elsif ($1 =~ /^contains\($/) {
                if( $rule =~ s/^\s*"([^"]*)"\s*\)// ) {
                    push @parts, qq{[text()[contains(string(.),"$1")]]};
                } elsif( $rule =~ s/^\s*'([^']*)'\s*\)// ) {
                    push @parts, qq{[text()[contains(string(.),"$1")]]};
                } else {
                    return( \@parts, $rule );
                    #die "Malformed string in :contains(): '$rule'";
                };
            } elsif ( $1 eq 'root') {
                # This will give surprising results if you do E > F:root
                $parts[$root_index] = $root;
            } elsif ( $1 eq 'empty') {
                push @parts, "[not(* or text())]";
            } else {
                Carp::croak "Can't translate '$1' pseudo-class";
            }
        }

        # Match combinators (whitespace, >, + and ~)
        if ($rule =~ s/$reg->{combinator}//) {
            my $match = $1;
            if ($match =~ />/) {
                push @parts, "/";
            } elsif ($match =~ /\+/) {
                push @parts, "/following-sibling::*[1]/self::";
            } elsif ($match =~ /\~/) {
                push @parts, "/following-sibling::";
            } elsif ($match =~ /^\s*$/) {
                push @parts, "//"
            } else {
                die "Weird combinator '$match'"
            }

            # new context
            undef $wrote_tag;
        }

        # Match commas
        if ($rule =~ s/$reg->{comma}//) {
            push @parts, " | ", "$root/"; # ending one rule and beginning another
            $root_index = $#parts;
            undef $wrote_tag;
        }
    }
    return \@parts, $rule
}

sub to_xpath {
    my $self = shift;
    my $rule = $self->{expression} or return;
    my %parms = @_;
    
    my($result,$leftover) = $self->consume( $rule, %parms );
    $leftover
        and die "Invalid rule, couldn't parse '$leftover'";
    return join '', @$result;

}

sub parse_pseudo { 
    # nop
}    

1;
__END__

=head1 NAME

HTML::Selector::XPath - CSS Selector to XPath compiler

=head1 SYNOPSIS

  use HTML::Selector::XPath;

  my $selector = HTML::Selector::XPath->new("li#main");
  $selector->to_xpath; # //li[@id='main']

  # functional interface
  use HTML::Selector::XPath 'selector_to_xpath';
  my $xpath = selector_to_xpath('div.foo');

  my $relative = selector_to_xpath('div.foo', root => '/html/body/p' );
  # /html/body/p/div[contains(concat(' ', @class, ' '), ' foo ')]

  my $relative = selector_to_xpath('div:root', root => '/html/body/p' );
  # /html/body/p/div

=head1 DESCRIPTION

HTML::Selector::XPath is a utility function to compile full set of
CSS2 and partial CSS3 selectors to the equivalent XPath expression.

=head1 FUNCTIONS and METHODS

=over 4

=item selector_to_xpath

  $xpath = selector_to_xpath($selector, %options);

Shortcut for C<< HTML::Selector->new(shift)->to_xpath(@_) >>. Exported upon request.

=item new

  $sel = HTML::Selector::XPath->new($selector, %options);

Creates a new object.

=item to_xpath

  $xpath = $sel->to_xpath;
  $xpath = $sel->to_xpath(root => "."); # ./foo instead of //foo

Returns the translated XPath expression. You can optionally pass
C<root> parameter, to specify which root to start the expression. It
defaults to C</>.

The optional C<prefix> option allows you to specify a namespace
prefix for the generated XPath expression.

=back

=head1 SUBCLASSING NOTES

=over 4

=item parse_pseudo

This method is called during xpath construction when we encounter a pseudo 
selector (something that begins with comma). It is passed the selector and 
a reference to the string we are parsing. It should return one or more 
xpath sub-expressions to add to the parts if the selector is handled, 
otherwise return an empty list.

=back

=head1 CAVEATS

=head2 CSS SELECTOR VALIDATION

This module doesn't validate whether the original CSS Selector
expression is valid. For example,

  div.123foo

is an invalid CSS selector (class names should not begin with
numbers), but this module ignores that and tries to generate
an equivalent XPath expression anyway.

=head1 COPYRIGHT

Tatsuhiko Miyagawa 2006-2011

Max Maischein 2011-

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

Most of the logic is based on Joe Hewitt's getElementsBySelector.js on
L<http://www.joehewitt.com/blog/2006-03-20.php> and Andrew Dupont's
patch to Prototype.js on L<http://dev.rubyonrails.org/ticket/5171>,
but slightly modified using Aristotle Pegaltzis' CSS to XPath
translation table per L<http://plasmasturm.org/log/444/>

Also see

L<http://www.mail-archive.com/www-archive@w3.org/msg00906.html>

and

L<http://kilianvalkhof.com/2008/css-xhtml/the-css3-not-selector/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<http://www.w3.org/TR/REC-CSS2/selector.html>
L<http://use.perl.org/~miyagawa/journal/31090>
L<https://en.wikibooks.org/wiki/XPath/CSS_Equivalents>

=cut
