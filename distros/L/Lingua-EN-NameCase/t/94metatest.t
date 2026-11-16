#!/usr/bin/perl -w
use strict;

use Test::More;

# Skip if doing a regular install
plan skip_all => "Author tests not required for installation"
    unless ( $ENV{AUTHOR_TESTING} );

use Test::Needs 'Test::CPAN::Meta';    # block form: no string eval

Test::CPAN::Meta->import();

plan 'no_plan';

exit;	# Don't use our own META.yml file

my $meta = meta_spec_ok(undef,undef,@_);

use Lingua::EN::NameCase;
my $version = $Lingua::EN::NameCase::VERSION;

is($meta->{version},$version,
    'META.yml distribution version matches');

if($meta->{provides}) {
    for my $mod (keys %{$meta->{provides}}) {
        is($meta->{provides}{$mod}{version},$version,
            "META.yml entry [$mod] version matches distribution version");

        # Load the module named in META and read its version without evaluating
        # a string built from META.  A name that is not a plain package name
        # (for example "Foo; system(...)") is refused.
        ok( $mod =~ m{\A[A-Za-z_]\w*(?:::\w+)*\z}, "META entry [$mod] is a plain package name" ) or next;
        ( my $file = "$mod.pm" ) =~ s{::}{/}g;
        eval { require $file; 1 };
        my $v = $mod->VERSION;
        is($meta->{provides}{$mod}{version},$v,
            "META.json entry [$mod] version matches module version");

        isnt($meta->{provides}{$mod}{version},0);
    }
}
