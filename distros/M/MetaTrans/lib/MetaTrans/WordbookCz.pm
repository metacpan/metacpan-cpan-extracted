=head1 NAME

MetaTrans::WordbookCz - MetaTrans plug-in for L<http://www.wordbook.cz/>

=cut

package MetaTrans::WordbookCz;

use strict;
use warnings;
use vars qw($VERSION @ISA);
use MetaTrans::Base;

use HTTP::Request;

$VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d", @r };
@ISA     = qw(MetaTrans::Base);

=head1 CONSTRUCTOR METHODS

=over 4

=item MetaTrans::WordbookCz->new(%options)

This method constructs a new MetaTrans::WordbookCz object and returns it. All
C<%options> are passed to C<< MetaTrans::Base->new >>. The method also sets
supported translation directions and the C<host_server> attribute.

=back

=cut

sub new
{
    my $class   = shift;
    my %options = @_;

    $options{host_server} = "www.wordbook.cz"
        unless (defined $options{host_server});

    my $self = new MetaTrans::Base(%options);
    $self = bless $self, $class;

    $self->set_languages("cze", "eng", "fre", "ger", "spa");

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
        eng => "enu",
        fre => "fra",
        ger => "ger",
        spa => "spa",
    );

    my $fsmer;
    my $fslovnik;

    if ($src_lang_code eq 'cze')
    {
        $fsmer    = 1;
        $fslovnik = $table{$dest_lang_code};
    }
    elsif ($dest_lang_code eq 'cze')
    {
        $fsmer    = 0;
        $fslovnik = $table{$src_lang_code};
    }

    my $request = HTTP::Request->new(POST => "http://www.wordbook.cz/index.php");
    $request->content_type('application/x-www-form-urlencoded');
    my $query = 
        "fextend=1" .
        "&fslovo=$expression" .
        "&fsmer=$fsmer" .
        "&fslovnik=$fslovnik";
    $request->content($query);

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
        <tr\s+[^>]*?>
        (<td\s+class="vyslradek"\s*>.*?)
        </tr>
    |gsix)
    {
        my $row = $1;
        $row =~ s/&nbsp;//g;
        my @data;
        while ($row =~ m/<td\s+class="vyslradek">(.*?)<\/td>/gixm)
        {
            push @data, $1;
        }
	my ($expr, $trans, $note);

	# exact words.
	if (@data == 5) {
	        (undef, $expr, undef, $trans, $note) = @data;

	# similar words.
	} elsif (@data == 3) {
		($expr, $trans, $note) = @data;
	}

        # skip blank values.
        next if $expr =~ /^\s*$/ || $trans =~ /^\s*$/;

        # normalize german.
        $expr = _normalize_german($expr, $note)
            if $src_lang_code eq 'ger';
        $trans = _normalize_german($trans, $note)
            if $dest_lang_code eq 'ger';

        # new result.
        push @result, ($expr, $trans);
    }

    return @result;
}

sub _normalize_german
{
    my $expr = shift;
    my $note = shift;

    if ($note && ($note eq 'die' || $note eq 'das' || $note eq 'der'))
    {
        $expr .= '; ' . substr($note, 2, 1);
    }

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
