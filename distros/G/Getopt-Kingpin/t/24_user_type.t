use strict;
use Test::More 0.98;
use Test::Exception;
use Getopt::Kingpin;
use Getopt::Kingpin::Command;

subtest 'foo' => sub {
    local @ARGV;
    push @ARGV, qw(foo);

    my $kingpin = Getopt::Kingpin->new();
    my $foo = $kingpin->arg("foo", "set foo")->foo();

    $kingpin->parse;

    is ref $foo, "Getopt::Kingpin::Arg";
    is $foo, "foo";
    is $foo->value, "foo";
};

subtest 'digest_md5' => sub {
    local @ARGV;
    push @ARGV, qw(md5);

    my $kingpin = Getopt::Kingpin->new();
    my $md5 = $kingpin->arg("md5", "set keyword")->digest_md5();

    $kingpin->parse;

    is ref $md5, "Getopt::Kingpin::Arg";
    is $md5, "1bc29b36f623ba82aaf6724fd3b16718";
    is $md5->value, "1bc29b36f623ba82aaf6724fd3b16718";
};

done_testing;

package Getopt::Kingpin::Type::Foo;
use strict;
use warnings;
use Carp;

sub set_value {
    my $self = shift;
    my ($value) = @_;

    if ($value eq "foo") {
        return $value;
    } else {
        croak "error";
    }
}

package Getopt::Kingpin::Type::DigestMd5;
use strict;
use warnings;
use Carp;
use Digest::MD5;

sub set_value {
    my $self = shift;
    my ($value) = @_;

    return Digest::MD5::md5_hex($value);
}

