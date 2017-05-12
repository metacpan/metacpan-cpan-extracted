package HTML::StripScripts::Regex;
use strict;
use warnings;
our $VERSION = '0.02';

=head1 NAME

HTML::StripScripts::Regex - XSS filter using a regular expression

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This class subclasses L<HTML::StripScripts>, and adds an input method
based on a regular expression.  See L<HTML::StripScripts>.

  use HTML::StripScripts::Regex;

  my $hss = HTML::StripScripts::Regex->new({ Context => 'Inline' });

  $hss->input("<i>hello, world!</i>");

  print $hss->filtered_document;

Using a regular expression to parse HTML is error prone and inefficient
for large documents.  If L<HTML::Parser> is available then
L<HTML::StripScripts::Parser> should be used in preference to this module.

=head1 METHODS

This subclass adds the following methods to those of L<HTML::StripScripts>.

=over

=item input ( TEXT )

Parses an HTML document and runs it through the filter.  TEXT must be the
entire HTML document to be filtered, as a single flat string.

=cut

use HTML::StripScripts;
use base qw(HTML::StripScripts);

sub input {
    my ($self, $text) = @_;

    $self->input_start_document;

    while ( $text =~ m[

      # <script></script> or <style></style> constructs,
      # in which everything between the tags counts as
      # CDATA.
      (?: <(script|style).*?> (.*?) </\1>           ) |

      # An HTML comment
      ( <!--.*?-->                                  ) |

      # A processing instruction
      ( <\?.*?>                                     ) |

      # A declaration 
      ( <\!.*?>                                     ) |

      # A start tag
      ( <[a-z0-9]+\b(?:[^>'"]|"[^"]*"|'[^']*')*>    ) |

      # An end tag
      ( </[a-z0-9]+>                                ) |

      # Some non-tag text.  We eat '<' only if it's
      # the first character, since a '<' as the
      # first character can't be the start of a well
      # formed tag or one of the patterns above would
      # have matched.
      ( .[^<]*                                       )

      ]igsx ) {
        
        if    ( defined $1 ) {
            $self->input_start("<$1>");
            $self->input_text($2);
            $self->input_end("</$1>");
        }
        elsif ( defined $3 ) {
            $self->input_comment($3);
        }
        elsif ( defined $4 ) {
            $self->input_process($4);
        }
        elsif ( defined $5 ) {
            $self->input_declaration($5);
        }
        elsif ( defined $6 ) {
            $self->input_start($6);
        }
        elsif ( defined $7 ) {
            $self->input_end($7);
        }
        elsif ( defined $8 ) {
            $self->input_text($8);
        }
        else {
            die 'regex failed to act as expected';
        }

    }

    $self->input_end_document;
}

=back

=head1 SUBCLASSING

The C<HTML::StripScripts::Regex> class is subclassable, in exactly the same
way as C<HMTL::StripScripts>.  See L<HTML::StripScripts/"SUBCLASSING"> for
details.

=head1 SEE ALSO

L<HTML::StripScripts>, L<HTML::StripScripts::Parser>, L<HTML::Parser>

=head1 AUTHOR

Nick Cleaton, C<< <nick at cleaton dot net> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nick Cleaton, all rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
