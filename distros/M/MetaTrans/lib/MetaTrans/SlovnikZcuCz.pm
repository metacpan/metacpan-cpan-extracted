=head1 NAME

MetaTrans::SlovnikZcuCz - MetaTrans plug-in for L<http://slovnik.zcu.cz/>

=cut

package MetaTrans::SlovnikZcuCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base qw(convert_to_utf8);

use Encode qw(decode_utf8 encode);
use HTTP::Request;
use URI::Escape;

$VERSION = do { my @r = (q$Revision: 1.1 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::SlovnikZcuCz->new(%options)

This method constructs a new MetaTrans::SlovnikZcuCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "slovnik.zcu.cz"
        unless (defined $options{host_server});

    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    # set supported languages
    $self->set_languages("cze", "eng");

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

    # convert to perl internal form
    $expression = decode_utf8($expression);

    # convert to iso-8859-2
    $expression = uri_escape(encode('iso-8859-2', $expression));

    my $request = HTTP::Request->new(POST => "http://slovnik.zcu.cz/online/index.php");
    $request->content_type('application/x-www-form-urlencoded');
    $request->content("word=$expression");

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

    # the output is in iso-8859-2 character encoding with HTML entities,
    # let's convert it to UTF-8
    $contents = convert_to_utf8('iso-8859-2', $contents);

    my @result;
    while ($contents =~ m|
        <form\s+name="addtranslate"[^>]*>\s+
        <input\s+type="hidden"\s+name="word"[^>]*>\s+
        <input\s+type="hidden"\s+name="page"\s+value="index.php">\s+
        <table\s+align="center">
        (.*?)
        </table>\s+
        <input\s+type="hidden"\s+name="polozek"[^>]*>
    |gsix)
    {

        push @result, _process_row($1, $src_lang_code);
    }

    return @result;
}

sub _process_row {
    my $string        = shift;
    my $src_lang_code = shift;

    my @result;
    my $actual;
    while ($string =~ m|<tr[^>]*>(.*?)</tr>|gsix)
    {
        my $td = $1;
        if ($td =~ m|<td[^>]*><h5>(.*?)</h5></td>|gsix)
        {
            $actual = $1;
        }
        elsif ($td =~ m|
            <td>([^<>]+?)</td>\s+
            <td>([^<>]+?)</td>\s+
            <td>.*?</td>\s+
            <td>.*?</td>\s+
            <td>.*?</td>
        |gsix)
        {
            my ($first, $second) = ($1, $2);
            if ($src_lang_code eq 'eng' && $actual =~ m|^Anglicko-Český\ssměr$|msx)
            {
                push @result, $first, $second;
            }
            elsif ($src_lang_code eq 'cze'
                && $actual =~ m|^Česko-Anglický\ssměr$|msx)
            {
                push @result, $second, $first;
            }
        }
    }
    return @result;
}


1;

__END__

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metatrans@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 AUTHOR

Michal Spacek, C<< <skim@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Michal Spacek, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<MetaTrans>, L<MetaTrans::Base>, L<MetaTrans::Languages>, L<Encode>
L<HTTP::Request>, L<URI::Escape>.
