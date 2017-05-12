# Copyright (C) 2008 Wes Hardaker
# License: Same as perl.  See the LICENSE file for details.
package Ham::Callsign;

sub new {
    my $type = shift;
    my ($class) = ref($type) || $type;
    my $self = {};
    %$self = @_;
    return bless($self, $class);
}

sub initialize_db {
    my ($self, $dbs) = @_;
    foreach my $db (@$dbs) {
	my $havedb = eval "require Ham::Callsign::DB::$db";
	if (!$havedb) {
	    Warn("failed to load Callsign DB of type $db");
	}
    }
}

sub Warn {
    warn @_;
}

1;

=pod

=head1 NAME

Ham::Callsign::DB

=head1 SYNOPSIS

use Ham::Callsign::DB;
my $db = new Ham::Callsign::DB();
$db->initalize_db("US");


=cut


