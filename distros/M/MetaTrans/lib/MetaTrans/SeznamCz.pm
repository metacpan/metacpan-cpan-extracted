=head1 NAME

MetaTrans::SeznamCz - MetaTrans plug-in for L<http://slovnik.seznam.cz/>

=cut

package MetaTrans::SeznamCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base;

use HTTP::Request;
use URI::Escape;

$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::SeznamCz->new(%options)

This method constructs a new MetaTrans::SeznamCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "slovnik.seznam.cz"
        unless (defined $options{host_server});

    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    $self->set_languages("cze", "eng", "ger", "fre", "spa", "ita", "rus");

    $self->set_dir_1_to_all("cze");
    $self->set_dir_all_to_1("cze");

    return $self;
}

=head1 METHODS

Methods are inherited from C<MetaTrans::Base>. Following methods are overriden:

=cut

=over 4

=item $plugin->create_request($expression, $src_lang_code, $dest_lang_code)

Create and return a C<HTTP::Request> object to be used for retrieving
translation of the C<$expression> from C<$src_lang_code> language to
C<$dest_lang_code> language.

=cut

sub create_request
{
    my $self           = shift;
    my $expression     = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my %table = (
        cze => "cz",
        eng => "en",
        ger => "de",
        fre => "fr",
        spa => "es",
        ita => "it",
        rus => "ru",
    );

    my $query =
        'http://slovnik.seznam.cz/?' .
        "q=" . uri_escape($expression) .
        "&lang=" . $table{$src_lang_code} . "_" . $table{$dest_lang_code};
    my $request = HTTP::Request->new(GET => $query);

    return $request;
}

=item $plugin->process_response($contents, $src_lang_code, $dest_lang_code)

Process the server response contents. Return the result of the translation in
an array of following form:

    (expression_1, translation_1, expression_2, translation_2, ...)

=back

=cut

sub process_response
{
    my $self           = shift;
    my $contents       = shift;
    my $src_lang_code  = shift;
    my $dest_lang_code = shift;

    my @result;
    while ($contents =~ m|
        <tr>
        \s*
        <td\sclass="word">
        \s*
        (.*?)
        \s*
        </td>
        \s*
        <td\sclass="translated">
        (.*?)
        </td>
        \s*
        </tr>
    |gsix)
    {
        my $expr  = _get_expr($1);
        my @trans = _get_trans($2);

        $expr = _normalize_german($expr)
            if $src_lang_code eq 'ger';

        foreach my $trans (@trans) {

            $trans = _normalize_german($trans)
                if $dest_lang_code eq 'ger';

            push @result, ($expr, $trans);
        }
    }

    return @result;
}

sub _get_expr
{
    my $string = shift;
    $string =~ s/<img[^>]+>//g;
    $string =~ s/<a\s+href="[^>]+"><\/a>//g;
    if ($string =~ m/<a\s+href="[^>]+">(.*?)<\/a>/)
    {
        return $1;
    }
    else
    {
        return '';
    }
}

sub _get_trans
{
    my $string = shift;
    $string =~ s/<br\s*\/>//g;
    $string =~ s/<img[^>]+>//g;
    $string =~ s/<a\s+href="[^>]+"><\/a>//g;
    $string =~ s/\s{2,}/ /g;
    my @result;
    while ($string =~ m/<a\s+href="[^>]+">(.*?)<\/a>/gimx)
    {
        push @result, $1;
    }
    return @result;
}

# normalize german article: Hund, r -> Hund; r
sub _normalize_german
{
    my $expr = shift;

    # normalize german article: Hund (der) -> Hund; r
    $expr = $1 . "; " . substr($2, 2, 1)
        if $expr =~ m/^(.*?),\s+(der|die|das)$/;

    return $expr;
}

1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metatrans@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Jan Pomikalek, C<< <xpomikal@fi.muni.cz> >>

=head1 COPYRIGHT & LICENSE

Copyright 2004 Jan Pomikalek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MetaTrans>, L<MetaTrans::Base>, L<MetaTrans::Languages>,
L<HTTP::Request>, L<URI::Escape>
