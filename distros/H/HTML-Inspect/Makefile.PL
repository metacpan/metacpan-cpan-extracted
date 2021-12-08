# This code is part of distribution HTML::Inspect.  It is licensed under the
# same terms as Perl itself: https://spdx.org/licenses/Artistic-2.0.html

use strict;
use warnings;
use utf8;
use 5.014;

use ExtUtils::MakeMaker;

my $git_url = 'https://github.com/markov2/perl5-HTML-Inspect';

WriteMakefile
  (
    NAME             => 'HTML::Inspect',
    VERSION          => '1.00',
    AUTHOR           => 'Mark Overmeer <markov@cpan.org>',
    PREREQ_PM        => {
        'Encode'         => 0,
        'File::Basename' => 0,
        'File::Slurper'  => 0.12,
        'Inline::C'      => 0,
        'Log::Report'    => 1.32,
        'Net::LibIDN2'   => 1.01,
        'Scalar::Util'   => 0,
        'Test::More'     => 0,
        'URI'            => 5.09,
        'XML::LibXML'    => 2.0207,
    },
    test             => {TESTS         => 't/*.t'},
    clean            => {FILES         => '*.bak'},
    MIN_PERL_VERSION => '5.014000',
    META_MERGE       => {
        dynamic_config => 0,
        'meta-spec'    => {version   => 2},
        no_index       => {directory => [ 't', 'xt', ]},
        prereqs        => {runtime   => {requires => {perl => '5.020000'}}},
        resources      => {
            bugtracker => {web => "$git_url/issues"},
            homepage   => 'http://perl.overmeer.net',
            license    => [ 'http://dev.perl.org/licenses/'],
            repository => {
                type => 'git',
                url => "$git_url.git",
                web => $git_url,
            },
        },
    },
);

sub MY::postamble { <<'__DIST' }
# for DIST
RAWDIR          = ../public_html/html-inspect/raw
DISTDIR         = ../public_html/html-inspect/source
LICENSE         = perl

# for POD
FIRST_YEAR      = 2021
EMAIL           = markov@cpan.org
WEBSITE         = http://perl.overmeer.net/CPAN/

# for HTML
HTML_OUTPUT     = ../public_html/html-inspect/html
HTML_DOCROOT    = /html-inspect/html
HTML_PACKAGE    = ../public_html/html-inspect/htmlpkg

__DIST
