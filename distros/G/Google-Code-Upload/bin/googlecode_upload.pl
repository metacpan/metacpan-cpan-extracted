#!/usr/bin/perl
use strict;
use warnings;
# ABSTRACT: script to upload files to a Google Code project
our $VERSION = '0.08'; # VERSION
# PODNAME: googlecode_upload.pl

use Getopt::Long;
use Pod::Usage;
use Term::ReadKey;
use Google::Code::Upload qw/upload/;


my %params;
GetOptions(
    \%params,
    'help|?',
    's|summary=s',
    'n|project=s',
    'u|user=s',
    'p|pass=s',
    'l|labels=s',
);

my $file = pop @ARGV;
unless ($file) { pod2usage(1); }
-e $file or die "$file is not found\n";

unless ( exists $params{n} ) {
    print 'Please enter your project name: ';
    while ( $params{n} = ReadLine(0) ) {
        chomp($params{n});
        last if $params{n};
    }
}
unless ( exists $params{u} ) {
    print 'Please enter your googlecode.com username: ';
    while ( $params{u} = ReadLine(0) ) {
        chomp($params{u});
        last if $params{u};
    }
}
unless ( exists $params{p} ) {
    ReadMode('noecho');
    print <<'END', ' ';
** Note that this is NOT your Gmail account password! **
It is the password you use to access Google Code repositories
and can be found here: http://code.google.com/hosting/settings
your password:
END
    while ( $params{p} = ReadLine(0) ) {
        chomp($params{p});
        last if $params{p};
    }
    ReadMode 'normal';
    print "\n";
}
unless ( exists $params{s} ) {
    print 'Please enter your file summary: ';
    while ( $params{s} = ReadLine(0) ) {
        chomp($params{s});
        last if $params{s};
    }
}

my @labels;
if ( exists $params{l} ) {
    @labels = split(/\,\s*/, $params{l} );
}
else {
    print "Please enter your file labels (eg: 'Featured, Type-Source, OpSys-All'): ";
    while ( my $labels = ReadLine(0) ) {
        chomp($labels);
        @labels = split(/\,\s*/, $labels);
        last;
    }
}

my $url = eval {
    upload( $file, $params{n}, $params{u}, $params{p}, $params{s}, \@labels )
};

if ($@) {
    print "An error occurred. Your file was not uploaded.\nGoogle Code upload server said: $@\n";
}
print "The file was uploaded successfully.\nURL: $url\n";

__END__

=pod

=encoding UTF-8

=head1 NAME

googlecode_upload.pl - script to upload files to a Google Code project

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    googlecode_upload.pl [options] FILE

=head1 OPTIONS

=over 4

=item B<-?>, B<--help>

=item B<s|summary>

Short description of the file

=item B<n|project>

Google Code project name

=item B<u|user>

Your Google Code Subversion username

=item B<p|pass=s>

Your Google Code Subversion password - from L<https://code.google.com/hosting/settings>

=item B<l|labels>

An optional list of labels to attach to the file

=back

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
