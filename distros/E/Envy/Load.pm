use strict;
package Envy::Load;
use Carp;
require Envy::DB;

$ENV{ENVY_CONTEXT} = $^X;

sub import {
    my ($me, @imports) = @_;
    my $db = Envy::DB->new(\%ENV);
    for my $pkg (@imports) {
	$db->envy(0, $pkg);
    }
    $db->commit;
    for ($db->warnings) { print STDERR $_; }
    $me->sync($db);
}

sub sync {
    my ($e, $db) = @_;
    for my $z ($db->to_sync()) {
	my ($k,$v) = @$z;
	if (defined $v) {
	    $ENV{$k} = $v;
	} else {
	    delete $ENV{$k};
	}
    }
}

sub new {
    my $class = shift;
    my %old = %ENV;
    bless \%old, $class;
}

sub load {
    my $e = shift;
    my $db = Envy::DB->new(\%ENV);
    for my $pkg (@_) {
	$db->envy(0, $pkg);
    }
    $db->commit;
    $e->sync($db);
    for ($db->warnings) { print STDERR $_; }
}

sub DESTROY {
    my $o = shift;
    %ENV = %$o;
}

1;
__END__

=head1 NAME

Envy::Load - Load Envy Files

=head1 SYNOPSIS

    use Envy::Load qw(dev objstore);

    {    
	my $env = Envy::Load->new();
	$env->load(qw(prod testdb));

	# %ENV restored when $env goes out of scope
    }

=head1 DESCRIPTION

Similar to `envy load ...`.

=cut
