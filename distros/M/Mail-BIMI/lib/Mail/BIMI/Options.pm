package Mail::BIMI::Options;
# ABSTRACT: Shared options
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;


has cache_backend => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_CACHE_BACKEND}//$ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND}//'File'},
  documentation => 'Cache backend to use for cacheing' );
has cache_fastmmap_share_file => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_CACHE_FASTMMAP_SHARE_FILE}//'/tmp/mail-bimi.fastmmap'},
  documentation => 'Shared cache file when using FastMmap backend' );
has cache_file_directory => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_CACHE_FILE_DIRECTORY}//'/tmp/'},
  documentation => 'Directory to store Cache files in when using File backend' );
has force_record => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_FORCE_RECORD}},
  documentation => 'Fake record to use' );
has http_client_timeout  => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_HTTP_CLIENT_TIMEOUT}//3},
  documentation => 'Timeout value for HTTP' );
has dns_client_timeout  => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_DNS_CLIENT_TIMEOUT}//5},
  documentation => 'Timeout value for DNS' );
has no_location_with_vmc => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_NO_LOCATION_WITH_VMC}},
  documentation => 'Do not check location if VMC was present' );
has no_validate_cert => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_CERT}},
  documentation => 'Do not validate VMC' );
has no_validate_svg => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_NO_VALIDATE_SVG}},
  documentation => 'Do not validate SVG' );
has require_vmc => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_REQUIRE_VMC}},
  documentation => 'Require VMC validation' );
has ssl_root_cert => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_SSL_ROOT_CERT}//undef},
  documentation => 'Location of SSL Root Cert Bundle - Defaults to Mozilla::CA bundle plus Known BIMI Root Certs' );
has strict_spf => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_STRICT_SPF}},
  documentation => 'Disallow SPF +all' );
has svg_from_file => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_SVG_FROM_FILE}},
  documentation => 'Fake SVG with file contents' );
has svg_max_fetch_size  => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_SVG_MAX_FETCH_SIZE}//65535},
  documentation => 'Maximum fetch size for SVG retrieval' );
has svg_max_size => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_SVG_MAX_SIZE}//32768},
  documentation => 'Maximum valid size for SVG' );
has svg_profile => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_SVG_PROFILE}//'SVG_1.2_PS'},
  documentation => 'Profile name to use for SVG validation' );
has verbose => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_VERBOSE}},
  documentation => 'Be More Verbose' );
has vmc_from_file => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_VMC_FROM_FILE}},
  documentation => 'Fake VMC with file contents' );
has vmc_no_check_alt => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_VMC_NO_CHECK_ALT}},
  documentation => 'Do not check the alt name of a VMC' );
has vmc_max_fetch_size  => ( is => 'rw', lazy => 1, default => sub {return $ENV{MAIL_BIMI_VMC_MAX_FETCH_SIZE}//65535},
  documentation => 'Maximum fetch size for VMC retrieval' );

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Options - Shared options

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for capturing caller options, which may be passed to the constructor, or set in environment

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 cache_backend

is=rw

Cache backend to use for cacheing

=head2 cache_fastmmap_share_file

is=rw

Shared cache file when using FastMmap backend

=head2 cache_file_directory

is=rw

Directory to store Cache files in when using File backend

=head2 dns_client_timeout

is=rw

Timeout value for DNS

=head2 force_record

is=rw

Fake record to use

=head2 http_client_timeout

is=rw

Timeout value for HTTP

=head2 no_location_with_vmc

is=rw

Do not check location if VMC was present

=head2 no_validate_cert

is=rw

Do not validate VMC

=head2 no_validate_svg

is=rw

Do not validate SVG

=head2 require_vmc

is=rw

Require VMC validation

=head2 ssl_root_cert

is=rw

Location of SSL Root Cert Bundle - Defaults to Mozilla::CA bundle plus Known BIMI Root Certs

=head2 strict_spf

is=rw

Disallow SPF +all

=head2 svg_from_file

is=rw

Fake SVG with file contents

=head2 svg_max_fetch_size

is=rw

Maximum fetch size for SVG retrieval

=head2 svg_max_size

is=rw

Maximum valid size for SVG

=head2 svg_profile

is=rw

Profile name to use for SVG validation

=head2 verbose

is=rw

Be More Verbose

=head2 vmc_from_file

is=rw

Fake VMC with file contents

=head2 vmc_max_fetch_size

is=rw

Maximum fetch size for VMC retrieval

=head2 vmc_no_check_alt

is=rw

Do not check the alt name of a VMC

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose|Moose>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
