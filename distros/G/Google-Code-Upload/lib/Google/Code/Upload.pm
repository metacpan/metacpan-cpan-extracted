package Google::Code::Upload;
use strict;
use warnings;
# ABSTRACT: upload files to a Google Code project (deprecated)
our $VERSION = '0.08'; # VERSION

use File::Basename qw/basename/;
use LWP::UserAgent;
use LWP::Protocol::https;
use HTTP::Request::Common;
use Scalar::Util qw/blessed/;
use Carp;



use Exporter qw(import);
our @EXPORT_OK = qw/ upload /;


sub new {
    my $class = shift;
    my %args  = @_;
    $args{$_} || croak "You must provide $_" for qw(username password project);

    if ( $args{username} =~ /^(.*?)\@gmail\.com$/ ) {
        $args{username} = $1;
    }
    my $agent_string = "$class/" . (defined $class->VERSION ? $class->VERSION : 'dev');

    my $self  = {
        ua          => $args{ua} || LWP::UserAgent->new( agent => $agent_string ),
        upload_uri  => "https://$args{project}.googlecode.com/files",
        password    => $args{password},
        username    => $args{username},
    };
    return bless $self, $class;
}


sub upload {
    my $self;
    my $summary;
    my $labels;
    my $file;
    my $description;

    if (blessed $_[0]) {
        $self = shift;
        my %args = @_;
        $file    = $args{file};
        $summary = $args{summary} || basename($file);
        $labels  = $args{labels} || [];
        $description = $args{description};
    }
    else {
        $file           = shift;
        my $project     = shift;
        my $username    = shift;
        my $password    = shift;
        $summary        = shift;
        $labels         = shift || [];
        $description    = shift;

        $self = __PACKAGE__->new(
            project     => $project,
            username    => $username,
            password    => $password,
        );
    }

    my $request = POST $self->{upload_uri},
        Content_Type => 'form-data',
        Content      => [
            summary  => $summary,
            ( $description ? (description => $description) : ()),
            ( map { (label => $_) } @$labels),
            filename => [$file, basename($file), Content_Type => 'application/octet-stream'],
        ];
    $request->authorization_basic($self->{username}, $self->{password});

    my $response = $self->{ua}->request($request);

    return $response->header('Location')
        if $response->code == 201;
    croak $response->status_line;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Google::Code::Upload - upload files to a Google Code project (deprecated)

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Google::Code::Upload;
    my $gc = Google::Code::Upload->new(
        project  => 'myproject',
        username => 'mike',
        password => 'abc123',
    );
    $gc->upload(
        file        => 'README',
        summary     => 'README for myproject',
        labels      => ['Featured'],
        description => 'Hello world',
    );

=head1 DESCRIPTION

B<DEPRECATED>: Google code L<shut down|http://google-opensource.blogspot.com/2015/03/farewell-to-google-code.html>

This module allows you to programmatically upload files to L<Google Code|https://googlecode.com>.

It ships with an executable script for use on the command line: L<googlecode_upload.pl>.

=head1 METHODS

=head2 new

Constructs a new C<Google::Code::Upload> object. Takes the following key-value
pairs:

=over 4

=item username

=item password (your Google Code password from L<https://code.google.com/hosting/settings>)

=item project

=item ua - something that works like a L<LWP::UserAgent> (I<optional>)

=back

=head2 upload

Upload the given file to Google Code. Requires the following key-value pairs:

=over 4

=item file - the filename of the file to upload

=item summary - the one-line summary to give to the file (defaults to the filename)

=item description - text describing the upload in more detail (for example, the
changelog entry for this release)

=item labels - an arrayref of labels like C<Featured>, C<Type-Archive> or C<OpSys-All>

=back

Returns the URL where the file can be downloaded if successful - otherwise, dies
with the HTTP status line.

You can also export the C<upload> function, if you don't want to use OO style.
Instead of key-value pairs, specify the arguments in the following order:

    use Google::Code::Upload qw(upload);
    upload( $file, $project_name, $username, $password, $summary, $labels, $description );

=head1 EXPORTS

You may optionally export C<upload> to use this module in a non-OO manner.

=head1 AVAILABILITY

The project homepage is L<http://search.cpan.org/dist/Google-Code-Upload/>.

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Google::Code::Upload/>.

=head1 SOURCE

The development version is on github at L<http://github.com/fayland/google-code-upload>
and may be cloned from L<git://github.com/fayland/google-code-upload.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://github.com/fayland/google-code-upload/issues>.

=head1 AUTHORS

=over 4

=item *

Fayland Lam <fayland@gmail.com>

=item *

Mike Doherty <doherty@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Fayland Lam <fayland@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
