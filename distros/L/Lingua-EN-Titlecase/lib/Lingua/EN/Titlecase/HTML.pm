package Lingua::EN::Titlecase::HTML;
use strict;
use warnings;
use parent "Lingua::EN::Titlecase";
use HTML::TokeParser;

sub lexer : method {
    my $self = shift;
    return $self->{_lexer} if $self->{_lexer};

    my $wp = $self->word_punctuation;
    my $wordish = $self->wordish_rx;

    $self->{_lexer} = sub {
        unless ( $self->{_raw_html} ) {
            my $tmp = $self->{_raw_html} = shift;
            $self->{_parser} = HTML::TokeParser->new(\$tmp);
        }

        if ( defined $self->{__text} and length $self->{__text} )
        {
            $self->{__text} =~ s/\A($wordish)// and return [ "word", "$1" ];
            $self->{__text} =~ s/\A(.)//s and return [ undef, "$1" ];
        }
        elsif ( my $token = $self->{_parser}->get_token() )
        {
            return [ undef, $token->[-1] ] unless $token->[0] eq "T";
            $self->{__text} = $token->[1];
            return $self->{_lexer}->();
        }
        else
        {
            $self->{_raw_html} = undef; # reset for next possible pass
            $self->{_parser} = undef;
            return ();
        }
    };
}

1;

__END__

=head1 NAME

Lingua::EN::Titlecase::HTML - Titlecase English words which contain HTML markup by traditional editorial rules.

=head1 DESCRIPTION

This is a subclass of L<Lingua::EN::Titlecase> which can handle
embedded HTML-like markup. The following will work fine-

 the <b>way</b> we <i>were</i>
 # Becomes...
 The <b>Way</b> We <i>Were</i>

Since L<HTML::TokeParser> is used to filter through the tags, even this
sort of thing will work-

 <a name="<what a stupid attr>">no title for you</a>.
 # Becomes...
 <a name="<what a stupid attr>">No Title for You</a>.

See L<Lingua::EN::Titlecase> for full usage.

=over 4

=item B<lexer>

Overrides the parent method to add in an HTML/SGML tag ignoring step
in the lexer.

=back

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008, Ashley Pond V C<< <ashley@cpan.org> >>.

This module is free software; you can redistribute it and modify it
under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty
for the software, to the extent permitted by applicable law. Except when
otherwise stated in writing the copyright holders and other parties
provide the software "as is" without warranty of any kind, either
expressed or implied, including, but not limited to, the implied
warranties of merchantability and fitness for a particular purpose. The
entire risk as to the quality and performance of the software is with
you. Should the software prove defective, you assume the cost of all
necessary servicing, repair, or correction.

In no event unless required by applicable law or agreed to in writing
will any copyright holder, or any other party who may modify or
redistribute the software as permitted by the above license, be
liable to you for damages, including any general, special, incidental,
or consequential damages arising out of the use or inability to use
the software (including but not limited to loss of data or data being
rendered inaccurate or losses sustained by you or third parties or a
failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of
such damages.

=cut
