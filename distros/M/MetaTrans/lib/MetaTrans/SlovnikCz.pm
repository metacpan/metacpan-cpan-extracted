=head1 NAME

MetaTrans::SlovnikCz - MetaTrans plug-in for L<http://www.slovnik.cz/>

=cut

package MetaTrans::SlovnikCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base;

use Encode;
use HTTP::Request;
use URI::Escape;

$VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::SlovnikCz->new(%options)

This method constructs a new MetaTrans::SlovnikCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "www.slovnik.cz"
        unless (defined $options{host_server});

    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    # set supported languages
    $self->set_languages("cze", "eng", "epo", "fre", "ger", "ita", "lat",
        "pol", "rus", "slo", "spa");

    $self->set_dir_1_to_spec("cze", "eng", "epo", "fre", "ger", "ita", "lat",
        "pol", "rus", "spa");
    $self->set_dir_spec_to_1("cze", "eng", "epo", "fre", "ger", "ita", "lat",
        "pol", "rus", "spa");

    # it also supports:
    # Slovak <-> Esperanto
    $self->set_dir_1_to_spec("slo", "epo");
    $self->set_dir_spec_to_1("slo", "epo");

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
        epo => "eo",
        fre => "fr",
        ger => "ge",
        ita => "it",
        lat => "la",
        pol => "pl",
        rus => "ru",
        slo => "sk",
        spa => "sp",
    );


    my $dict;
    if ($src_lang_code eq 'cze' || $dest_lang_code eq 'cze') {
        $dict = $table{'cze'};
    } elsif ($src_lang_code eq 'slo' || $dest_lang_code eq 'slo') {
        $dict = $table{'slo'};
    }
    my $dir = ($src_lang_code eq 'cze' || $src_lang_code eq 'slo') ?
        $table{$dest_lang_code} . $dict . "." . $dict :
        $table{$src_lang_code}  . $dict . "." . $table{$src_lang_code};

    my $query = "http://www.slovnik.cz/bin/mld.fpl" .
        "?lines=50&hptxt=0&use_cookies=0&js=0" .
        "&vcb=" . uri_escape($expression) .
        "&dictdir=$dir";
    my $request = new HTTP::Request("GET", $query);

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
        <div\s+class="pair">
        \s*
        <span\s+class="l">
        (.*?)
        </span>
        \s*-\s*
        <span\s+class="r">
        (.*?)
        </span>
        \s*
        </div>
    |gsix)
    {
        my $expr = _remove_html($1);
        my $trans = _remove_html($2);;

        push @result, (
            &_postprocess_expr($expr, $src_lang_code),
            &_postprocess_expr($trans, $dest_lang_code),
        );
    }

    return @result;
}

sub _postprocess_expr
{
    my $expr     = shift;
    my $lang     = shift;

    # convert $expr to perl's internal UTF-8 format
    # (to ensure correct regexes functionality)
    my $expr_dec = decode_utf8($expr);

    # strip blanks
    $expr_dec =~ s/\s+/ /g;
    $expr_dec =~ s/^ //;

    # insert missing blanks after . or , or ;
    $expr_dec =~ s/(\w)([.,;])(\w)/$1$2 $3/g;

    # normalize german article: Hund (der) -> Hund; r
    if ($lang eq 'ger')
    {
        $expr_dec = $1 . "; " . substr($2, 2, 1)
            if $expr_dec =~ /^(.*) \((der|die|das)\)$/;
    }

    # convert back from internal format
    return encode_utf8($expr_dec);
}

sub _remove_html
{
    my $string = shift;
    $string =~ s/<i title="gnu">g<\/i>//g;
    $string =~ s/<a\s+href="[^>]+">//g;
    $string =~ s/<\/a>//g;
    return $string;
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
