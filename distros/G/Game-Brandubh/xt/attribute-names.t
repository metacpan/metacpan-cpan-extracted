#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# AN ATTRIBUTE EATS A METHOD OF THE SAME NAME, AND AN XSUB IS A METHOD.
#
# Object::Proto::Sugar installs an accessor for every `has`, into the package,
# under the attribute's own name. If the package already has something there
# the accessor replaces it and nothing is said. Game::Brandubh::Rules was
# written with `has _position` and `has _variant` beside XSUBs called
# `_position` and `_variant`: the XSUBs vanished, `$self->_position` handed the
# object's address to nobody, and the first symptom was a position "refused,
# code 4" from a constructor that had been given no position at all.
#
# A grep of the .pm for `sub NAME` does not find it. The other name is in
# Brandubh.xs. This reads both.

my %xsub;
{
    open my $xs, '<', 'Brandubh.xs' or die "Brandubh.xs: $!";
    my $package;
    while (my $line = <$xs>) {
        $package = $1 if $line =~ /^MODULE\s*=\s*\S+\s+PACKAGE\s*=\s*(\S+)/;
        $xsub{$package}{$1} = 1 if defined $package && $line =~ /^(_?[a-z][a-z_0-9]*)\(/;
    }
}
cmp_ok(scalar(keys %xsub), '>=', 2, 'the XS file was read: ' . join(', ', sort keys %xsub));

my @modules = sort glob('lib/Game/Brandubh/*.pm'), 'lib/Game/Brandubh.pm';
my $with_attributes = 0;
for my $file (@modules) {
    open my $fh, '<', $file or die "$file: $!";
    my ($package, @has, %sub, %list, $filling);
    while (my $line = <$fh>) {
        last if $line =~ /^__END__/;
        $package = $1 if $line =~ /^package\s+(\S+);/;
        push @has, $1 if $line =~ /^has\s+(\w+)/;
        $sub{$1} = 1 if $line =~ /^sub\s+(\w+)/;

        # `has [@FLAGS]` declares one attribute a name in a list filled in a
        # BEGIN block a few lines up. Read the list: @NAME = qw( ... );
        if ($line =~ /^\s*\@(\w+)\s*=\s*qw\(/) { $filling = $1; $line =~ s/^.*?qw\(// }
        if (defined $filling) {
            my $done = $line =~ s/\).*//s;
            push @{ $list{$filling} }, grep { length } split ' ', $line;
            undef $filling if $done;
        }
        push @has, @{ $list{$1} || [] } if $line =~ /^has\s+\[\@(\w+)\]/;
        push @has, split ' ', $1 if $line =~ m{^has\s+\[qw[/(]([^/)]*)[/)]\]};
    }
    next unless @has;
    $with_attributes++;
    my @hit = grep { $sub{$_} || $xsub{$package}{$_} } @has;
    is("@hit", '', "$package: none of (@has) is also a sub or an XSUB");
    ok(!$sub{has}, "$package has no method called has");
}
cmp_ok($with_attributes, '>=', 2, "$with_attributes classes declare attributes");

done_testing();
