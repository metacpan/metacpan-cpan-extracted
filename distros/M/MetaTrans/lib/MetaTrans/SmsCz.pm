=head1 NAME

MetaTrans::SmsCz - MetaTrans plug-in for L<http://slovniky.sms.cz/>

=cut

package MetaTrans::SmsCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base qw(convert_to_utf8);

use Encode;
use HTTP::Request;

$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::SmsCz->new(%options)

This method constructs a new MetaTrans::SmsCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "slovniky.sms.cz"
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

    # convert to Perl's internal UTF-8 format
    $expression = Encode::decode_utf8($expression)
        unless Encode::is_utf8($expression);
    
    # replace blanks with pluses (+)
    $expression =~ s/\s+/+/g;

    # convert to cp1250 character encoding (that's what server expects)
    $expression = Encode::encode("cp1250", lc $expression)
	if $src_lang_code ne 'rus';

    # do some server-specific character escapings
    $expression = &_my_escape($expression);

    my $query = 
        "http://slovniky.sms.cz/index.php?" .
        "P_id_kategorie=65456" .
        "&P_soubor=/slovniky/index.php" .
        "&send_data=1" .
        "&word=$expression" .
        "&bjvolba=" . $table{$src_lang_code} . "_" . $table{$dest_lang_code};
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
        <a\s[^>]*>\s*([^<]*?)\s*</a>
        \s*</td>\s*<td\s[^>]*>
        \s*&nbsp;-&nbsp;
        \s*</td>\s*<td\s[^>]*>
        \s*<a\s[^>]*>\s*([^<]*?)\s*</a>
    |gsix)
    {
        # the output is in cp1250 character encoding with HTML entities,
        # let's convert it to UTF-8
        my $expr  = convert_to_utf8('cp1250', $1);
        my $trans = convert_to_utf8('cp1250', $2);

        $expr = &_normalize_german_article($expr)
            if $src_lang_code eq 'ger';

        $trans = &_normalize_german_article($trans)
            if $dest_lang_code eq 'ger';
        
        push @result, ($expr, $trans);
    }

    return @result;
}

# server specific character escaping
# it's really strange, so don't worry if you don't understand it
sub _my_escape
{
    my $unesc = shift;
    my $result;

    foreach my $char (split //, $unesc)
    {
        my $ord = ord($char);
        $result .= $ord>>4 == 0x43 ? sprintf('%%E%X', $ord & 0xf) :
                   $ord>>4 == 0x44 ? sprintf('%%F%X', $ord & 0xf) :
                   $ord    == 0x2B ? '+'                          :
                                     sprintf('%%%X', $ord);
    }

    return $result;
}

# der Hund -> Hund; r
sub _normalize_german_article
{
    my $expr = shift;
    my $expr_dec = decode_utf8($expr);
    
    $expr_dec = $2 . "; " . substr($1, 2, 1)
        if $expr_dec =~ /^(der|die|das) (\w+)$/;
    
    return Encode::encode_utf8($expr_dec);
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
