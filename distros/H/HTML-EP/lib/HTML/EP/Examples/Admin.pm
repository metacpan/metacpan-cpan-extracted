# -*- perl -*-
#
#   HTML::EP	- A Perl based HTML extension.
#
#
#   Copyright (C) 1998    Jochen Wiedmann
#                         Am Eisteich 9
#                         72555 Metzingen
#                         Germany
#
#                         Phone: +49 7123 14887
#                         Email: joe@ispsoft.de
#
#   All rights reserved.
#
#   You may distribute this module under the terms of either
#   the GNU General Public License or the Artistic License, as
#   specified in the Perl README file.
#
############################################################################

require 5.004;
use strict;

use HTML::EP ();
use HTML::EP::Locale ();

package HTML::EP::Examples::Admin;

$HTML::EP::Examples::Admin::VERSION = '0.03';
@HTML::EP::Examples::Admin::ISA = qw(HTML::EP::Locale HTML::EP);


sub init {
    my $self = shift;
    if (!exists($self->{'admin_config'})) {
        $self->SUPER::init();
        $self->{'admin_config'} =
	    $self->{'_ep_config'}->{'examples'}->{'admin'} || {};
	$self->{'admin_config'}->{'vardir'} ||= '/home/httpd/html/admin/var';
    }
}


sub _prefs {
    my $self = shift; my $prefs = shift;
    my $vardir = $self->{'admin_config'}->{'vardir'};
    my $prefs_file = "$vardir/prefs";
    if (!$prefs) {
        # Load Prefs
        $self->{'prefs'} = (do $prefs_file) || {};
    } else {
        # Save Prefs
        require Data::Dumper;
        my $dump = Data::Dumper->new([$prefs], ['PREFS']);
	$dump->Indent(1);
	require Symbol;
	my $fh = Symbol::gensym();
	my $d = $dump->Dump();
        if ($self->{'debug'}) {
	    print "Saving Preferences to $prefs_file.\n";
            $self->print("Saving data:\n$d\n");
	}
        if (!open($fh, ">$prefs_file")
	    or  !(print $fh "$d\n")
	    or  !close($fh)) {
            die "Couldn't save data: $!";
        }
	$self->{'prefs'} = $prefs;
    }
}


sub _ep_html_ep_examples_admin_squid {
    my $self = shift; my $attr = shift;
    my $cgi = $self->{'cgi'};
    my $prefs = $self->_prefs();
    my $debug = $self->{'debug'};

    my $verify_squid_range = sub {
        my($from, $to, $active, $name) = @_;

	require Socket;
	my($f, $t);
	if (!($f = Socket::inet_aton($from))) {
	    die "Invalid IP address: $from";
	}
	if (!($t = Socket::inet_aton($to))) {
	    die "Invalid IP address: $to";
	}
	{
	    'from' => Socket::inet_ntoa($f),
	    'to' => Socket::inet_ntoa($t),
	    'active' => $active,
	    'name' => $name
	}
    };

    my @range;
    my $modified;
    my $from = $cgi->param('insert_ip_from');
    my $to = $cgi->param('insert_ip_to');
    if ($from  or  $to) {
        push(@range,
	     &$verify_squid_range($from, $to, $cgi->param("insert_active"),
				  $cgi->param("insert_name")));
	$modified = 1;
    }
    for (my $i = 0;  1;  $i++) {
        if ($cgi->param("delete_ip_$i")) {
	    $modified = 1;
	    next;
	}
	$from = $cgi->param("edit_ip_from_$i");
	$to = $cgi->param("edit_ip_to_$i");
	if (!defined($from)  &&  !defined($to)) {
	    last;
	}
	push(@range,
	     &$verify_squid_range($from, $to, $cgi->param("edit_active_$i"),
				  $cgi->param("edit_name_$i")));
	$modified = 1;
    }

    if ($modified) {
	$self->print("Modifications detected.\n") if $debug;
        $prefs->{'squid_ranges'} = \@range;
	$self->_prefs($prefs);
	my $path_users_modified =
	    ($attr->{'users-modified-path'}  ||
	     $self->{'admin_config'}->{'users_modified_path'})
		or die "Path of usersModified binary not set";
	if ($path_users_modified ne 'none') {
	    die "No such binary: $path_users_modified"
		unless -f $path_users_modified;
	    my @command = ($path_users_modified, '--squid');
	    foreach my $r (@range) {
		next unless $r->{'active'};
		push(@command,
		     "--range", "$r->{'from'},$r->{'to'},$r->{'name'}");
	    }
	    $self->print("Executing command: ", join(" ", @command), "\n")
		if $debug;
	    system @command;
	}
    } else {
	$self->print("No modifications detected.\n") if $debug;
        $prefs->{'squid_ranges'} ||= [];
    }
    @range = sort { $a->{name} cmp $b->{name}} @{$prefs->{'squid_ranges'}};
    $self->{'ranges'} = \@range;
    if ($debug) {
        $self->print("Squid IP ranges:\n");
	foreach my $r (@{$prefs->{'squid_ranges'}}) {
	    $self->printf("    Name %s, From %s, To %s, Active %s\n",
			  $r->{'name'}, $r->{'from'}, $r->{'to'},
			  $r->{'active'});
	}
    }

    $self->{'admin_config'}->{'squid_conf_path'} ||= '/etc/squid.conf';
    '';
}

sub _format_RANGE_SELECTED {
    my $self = shift;  my $val = shift;
    $val ? "" : "SELECTED";
}
