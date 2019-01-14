=head1 NAME

Devel::TRay - See what your code's doing

=head1 AUTHOR

Pavel P. Serikov <pavelr@cpan.org>

=head1 LICENCE

Perl5

=head1 SYNOPSIS

    #!/usr/bin/perl -d:TRay

or

    perl -d:TRay script.pl
	
=head1 DESCRIPTION

Fork of L<Devel::CallTrace> with following additions

=over

=item *

Filter output as easy as L<Devel::KYTProf>
	   
=item *
	    
Ability to not show public and CORE module calls

=back

See module tests for more details.
    
=head1 FILTERS USAGE

You can use multiple filters with syntax like

    -d:TRay=subs_matching=X:hide_core=1:hide_cpan=1:hide_eval=1:show_lines=0

( import options are separated with ':' symbol )

=cut

package Devel::TRay;
use warnings;
use strict;
no strict 'refs';

use vars qw($SUBS_MATCHING);
our $VERSION = '0.03';
our $calls = [];
our $ARGS;
our $SUBS_MATCHING = qr/.*/;

sub _get_args {
    my ( $arg_str ) = @_;
    return if !$arg_str;
    my $res;
    my @x = split( ':', $arg_str);
    for my $i (@x) {
        my @y = split( '=', $i );
        $res->{ $y[0] } = $y[1]; 
    }
    return $res;
}

sub import {
    my ( $self, $import_tags ) = @_;
    $ARGS = _get_args($import_tags);
    
    my $re = $ARGS->{subs_matching} if $ARGS;

    if ($re) {
        $Devel::TRay::SUBS_MATCHING = qr/$re/;
    }
}

package DB;
use Data::Dumper;
use List::Util qw(uniq);
use MetaCPAN::Client;
use Module::CoreList;
sub DB{};
our $CALL_DEPTH = 0;
our $traced_modules = [];
my $indent = $Devel::TRay::ARGS->{indent} || "  ";
my $mcpan = MetaCPAN::Client->new( version => 'v1' );

sub _get_enabled_module_filters {
    return [ grep { $_ =~ 'hide_' && $Devel::TRay::ARGS->{$_} } sort keys %{$Devel::TRay::ARGS} ];
}

sub sub {
    local $DB::CALL_DEPTH = $DB::CALL_DEPTH+1;
    Devel::TRay::called($DB::CALL_DEPTH, \@_) 
        if ($DB::sub =~ $Devel::TRay::SUBS_MATCHING);
    &{$DB::sub};
}


sub Devel::TRay::called {
    my ( $depth, $routine_params ) = @_;
    my $frame = { 'sub' => "$DB::sub", 'depth' => $depth };
    if (exists $DB::sub{$DB::sub}) {
        $frame->{'line'} = $DB::sub{$DB::sub};
    }
    push @$calls, $frame;
}

# return Data::Dumper from Data::Dumper::Dumper()
sub _extract_module_name {
    my ($sub) = @_;
    my @x = split( '::', $sub );
    return $x[0] if ( scalar @x == 1 );
    pop @x;
    return join( '::', @x );
}

sub _is_cpan_published {
    my ($pkg, $severity) = @_;
    return 0 if !defined $pkg;
	$severity = 2 if !defined $severity;
    
	if ( $severity == 0 ) {
		eval {
			return $mcpan->module($pkg)->distribution;
		} or do {
			return 0;
		}
	}
	
	elsif ( $severity == 1 ) {
	    my $expected_distro = $pkg;
	    $expected_distro =~ s/::/-/g;
		eval {
			return $mcpan->distribution($expected_distro)->name;
		} or do {
			return 0;
		}
	}
	
	elsif ( $severity == 2 ) {
	    my $expected_distro = $pkg;
	    $expected_distro =~ s/::/-/g;
			
		my $success = eval {
			$mcpan->distribution($expected_distro)->name;
		};
		return $success if $success;
		
		$success = eval {
			$mcpan->module($pkg)->distribution;
		};
		
		if ( $success ) {
			# exceptions
			return $success if ( $success eq 'Moo' );
			return $success if ( $success eq 'Moose' );
			
			# $pkg can be Sub::Defer and $success is Sub-Quote
			my $root_namespace = (split( '-', $success))[0];
			return $success if ( $pkg =~ qr/$root_namespace/ );
		}
		
		return 0;
	}
    
	else {
		die "Wrong or non implemented severity value";
	}
}

sub _is_core {
    my ($pkg) = @_;
    return 0 if !defined $pkg;
    return Module::CoreList::is_core(@_);
}

sub _is_eval {
    my ($pkg) = @_;
    return 0 if !defined $pkg;
    return 1 if ( $pkg eq '(eval)' );
    return 0;
}

sub _check_filter {
    my ($option, $pkg) = @_;
    # dispatch table
    # all functions must return true when value need to be removed
    my %actions = (
        'hide_cpan' => \&_is_cpan_published,
        'hide_core' => \&_is_core,
        'hide_eval' => \&_is_eval
    );
	my $res = $actions{$option}->($pkg);
	# print STDERR "$option\t$pkg\t$res\n";
    return $res;
}

# return 1 if module must be leaved in stacktrace
sub _leave_in_trace {
    my ( $module, $filters ) = @_;
	
	die "No filters specified" if !defined $filters;
	
    for my $f (@$filters) {
        return 0 if ( _check_filter( $f, $module ) );
    }
    return 1;
}

sub _filter_calls {
    my ( $calls ) = @_;
	
	@$calls = grep { $_->{'sub'} !~ /CODE/ } @$calls;
	
	my $subs = [ map { $_->{'sub'} } @$calls ];
	$traced_modules = [ uniq map { _extract_module_name($_) } @$subs ];

	@$traced_modules = grep { $_ ne 'Devel::TRay' } @$traced_modules;
	
	my $filters = _get_enabled_module_filters();
    @$traced_modules = grep { _leave_in_trace($_, $filters) } @$traced_modules;
	
	my %modules_left = map { $_ => 1 } @$traced_modules;
    @$calls = grep { $modules_left{_extract_module_name($_->{'sub'})} } @$calls;
    
    return { 'calls' => $calls, 'traced' => $traced_modules };
}

sub _print {
    my ( $frame ) = @_;
    my $str = $indent x $frame->{'depth'} . $frame->{'sub'};
    $str.= " (".$frame->{'line'}.")" if ( $frame->{'line'} && $Devel::TRay::show_lines );
    print STDERR "$str\n";
}

END {
	_filter_calls($calls);
    _print($_) for @$calls;
}

1;
