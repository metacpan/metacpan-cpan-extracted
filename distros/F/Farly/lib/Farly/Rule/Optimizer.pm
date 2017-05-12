package Farly::Rule::Optimizer;

use 5.008008;
use strict;
use warnings;
use Carp;
use Log::Any qw($log);

use Farly::Template::Cisco;

our $VERSION = '0.26';

sub new {
    my ( $class, $rules ) = @_;

    confess "Farly::Object::List object required"
      unless ( defined($rules) );

    confess "Farly::Object::List object required"
      unless ( $rules->isa('Farly::Object::List') );

    my $self = {
        RULES      => $rules,
        OPTIMIZED  => Farly::Object::List->new(),
        REMOVED    => Farly::Object::List->new(),
        P_ACTION   => 'permit',
        D_ACTION   => 'deny',
        MODE       => 'L4',
        PROTOCOLS  => [ 0, 6, 17 ],
        PROPERTIES => [ 'PROTOCOL', 'SRC_IP', 'SRC_PORT', 'DST_IP', 'DST_PORT' ],
        VERBOSE  => undef,
        TEMPLATE => Farly::Template::Cisco->new('ASA'),
    };

    bless $self, $class;

    
    $log->info("$self NEW");
    $log->info( "$self RULES " . $self->{RULES} );

    #validate input rule set
    $self->_is_valid_rule_set();
    $self->_is_expanded();

    return $self;
}

sub rules       { return $_[0]->{RULES}; }
sub optimized   { return $_[0]->{OPTIMIZED}; }
sub removed     { return $_[0]->{REMOVED}; }
sub p_action    { return $_[0]->{P_ACTION}; }
sub d_action    { return $_[0]->{D_ACTION}; }
sub _mode       { return $_[0]->{MODE}; }
sub _protocols  { return @{ $_[0]->{PROTOCOLS} }; }
sub _properties { return @{ $_[0]->{PROPERTIES} }; }
sub _is_verbose { return $_[0]->{VERBOSE}; }
sub _template   { return $_[0]->{TEMPLATE}; }

sub _is_valid_rule_set {
    my ($self) = @_;

    my $id = $self->rules->[0]->get('ID');

    my $search = Farly::Object->new();
    $search->set( 'ENTRY', Farly::Value::String->new('RULE') );
    $search->set( 'ID',    $id );

    foreach my $rule ( $self->rules->iter() ) {
        if ( $rule->has_defined('REMOVE') ) {
            die "found REMOVE in firewall ruleset ", $rule->dump();
        }
        if ( !$rule->matches($search) ) {
            die "found invalid object in firewall ruleset ", $rule->dump();
        }
    }
}

sub _is_expanded {
    my ($self) = @_;
    foreach my $rule ( $self->rules->iter() ) {
        foreach my $key ( $rule->get_keys() ) {
            if ( $rule->get($key)->isa('Farly::Object::Ref') ) {
                die "an expanded firewall ruleset is required";
            }
        }
    }
}

sub verbose {
    my ( $self, $flag ) = @_;
    $self->{VERBOSE} = $flag;
}

sub set_p_action {
    my ( $self, $action ) = @_;
    confess "invalid action" unless ( defined($action) && length($action) );
    $self->{P_ACTION} = $action;
    
    $log->debug("set permit action to $action");
}

sub set_d_action {
    my ( $self, $action ) = @_;
    confess "invalid action" unless ( defined($action) && length($action) );
    $self->{D_ACTION} = $action;
    
    $log->debug("set deny action to $action");
}

# sort rules in ascending order by line number
sub _ascending_LINE {
    $a->get('LINE')->compare( $b->get('LINE') );
}

sub set_l4 {
    my ($self) = @_;
    $self->{MODE}       = 'L4';
    $self->{PROTOCOLS}  = [ 0, 6, 17 ];
    $self->{PROPERTIES} = [ 'PROTOCOL', 'SRC_IP', 'SRC_PORT', 'DST_IP', 'DST_PORT' ];
}

# sort rules in ascending order so that current can contain next
# but next can't contain current
sub _ascending_l4 {
         $a->get('DST_IP')->compare( $b->get('DST_IP') )
      || $a->get('SRC_IP')->compare( $b->get('SRC_IP') )
      || $a->get('DST_PORT')->compare( $b->get('DST_PORT') )
      || $a->get('SRC_PORT')->compare( $b->get('SRC_PORT') )
      || $a->get('PROTOCOL')->compare( $b->get('PROTOCOL') );
}

sub set_icmp {
    my ($self) = @_;

    
    $log->info("set_icmp mode");

    $self->{MODE}       = 'ICMP';
    $self->{PROTOCOLS}  = [ 0, 1 ];
    $self->{PROPERTIES} = [ 'PROTOCOL', 'SRC_IP', 'DST_IP', 'ICMP_TYPE' ];
}

sub _ascending_icmp {
         $a->get('DST_IP')->compare( $b->get('DST_IP') )
      || $a->get('SRC_IP')->compare( $b->get('SRC_IP') )
      || $a->get('ICMP_TYPE')->compare( $b->get('ICMP_TYPE') )
      || $a->get('PROTOCOL')->compare( $b->get('PROTOCOL') );
}

sub set_l3 {
    my ($self) = @_;

    

    $log->info("set_l3 mode");

    my $ICMP = Farly::Object->new();
    $ICMP->set( 'PROTOCOL', Farly::Transport::Protocol->new(1) );

    my $TCP = Farly::Object->new();
    $TCP->set( 'PROTOCOL', Farly::Transport::Protocol->new(6) );

    my $UDP = Farly::Object->new();
    $UDP->set( 'PROTOCOL', Farly::Transport::Protocol->new(17) );

    my %protocols;

    foreach my $rule ( $self->rules->iter() ) {

        next if $rule->matches($ICMP);
        next if $rule->matches($TCP);
        next if $rule->matches($UDP);

        if ( $rule->has_defined('PROTOCOL') ) {
            $protocols{ $rule->get('PROTOCOL')->as_string() }++;
        }
        else {
            $log->info( "set_l3 skipped:\n" . $rule->dump() );
        }
    }

    my @p = keys %protocols;

    $self->{MODE}       = 'L3';
    $self->{PROTOCOLS}  = \@p;
    $self->{PROPERTIES} = [ 'PROTOCOL', 'SRC_IP', 'DST_IP' ];
}

sub _ascending_l3 {
    $a->get('DST_IP')->compare( $b->get('DST_IP') )
      || $a->get('SRC_IP')->compare( $b->get('SRC_IP') )
      || $a->get('PROTOCOL')->compare( $b->get('PROTOCOL') );
}

sub run {
    my ($self) = @_;

    $self->_optimize();

    $self->{OPTIMIZED} = $self->_keep( $self->rules );
    $self->{REMOVED}   = $self->_remove( $self->rules );
}

sub _do_search {
    my ( $self, $action ) = @_;

    
 
    my $search = Farly::Object->new();
    my $result = Farly::Object::List->new();

    foreach my $protocol ( $self->_protocols ) {

        $log->info("searching for $action $protocol");

        $search->set( 'PROTOCOL', Farly::Transport::Protocol->new($protocol) );
        $search->set( 'ACTION',   Farly::Value::String->new($action) );

        $self->rules->matches( $search, $result );
    }

    return $result;
}

sub _tuple {
    my ( $self, $rule ) = @_;

    

    my $r = Farly::Object->new();

    my @rule_properties = $self->_properties();

    foreach my $property (@rule_properties) {
        if ( $rule->has_defined($property) ) {
            $r->set( $property, $rule->get($property) );
        }
        else {
            $log->warn( "property $property not defined in " . $rule->dump() );
        }
    }

    return $r;
}

# Given rule X, Y, where X precedes Y in the ACL
# X and Y are inconsistent if:
# Xp contains Yd
# Xd contains Yp

sub _inconsistent {
    my ( $self, $s_a, $s_an ) = @_;

    # $s_a = ARRAY ref of rules of action a
    # $s_an = ARRAY ref of rules of action !a
    # $s_a and $s_an are sorted by line number and must be readonly

    my $rule_x;
    my $rule_y;

    # iterate over rules of action a
    for ( my $x = 0 ; $x != scalar( @{$s_a} ) ; $x++ ) {

        $rule_x = $s_a->[$x];

        confess "error : rule_x defined remove"
          if ( $rule_x->has_defined('REMOVE') );

        # iterate over rules of action !a
        for ( my $y = 0 ; $y != scalar( @{$s_an} ) ; $y++ ) {

            $rule_y = $s_an->[$y];

            #skip check if rule_y is already removed
            next if $rule_y->has_defined('REMOVE');

            # if $rule_x comes before $rule_y in the rule set
            # then check if $rule_x contains $rule_y

            if ( $rule_x->get('LINE')->number() <= $rule_y->get('LINE')->number() )
            {

                # $rule_x1 is rule_x with layer 3 and 4 properties only
                my $rule_x1 = $self->_tuple($rule_x);

                if ( $rule_y->contained_by($rule_x1) ) {

                    # note removal of rule_y and the
                    # rule_x which caused the inconsistency
                    $rule_y->set( 'REMOVE', Farly::Value::String->new('RULE') );
                    $self->_log_remove( $rule_x, $rule_y );
                }
            }
        }
    }
}

# Given rule X, Y, where X precedes Y in the ACL
# if Yp contains Xp and there does not exist rule Zd between
# Xp and Yp such that Zd intersect Xp and Xp !contains Zd

sub _can_remove {
    my ( $self, $rule_x, $rule_y, $s_an ) = @_;

    # $rule_x = the rule contained by $rule_y
    # $s_an = rules of action !a sorted by ascending DST_IP

    # $rule_x1 is rule_x with layer 3 and 4 properties only
    my $rule_x1 = $self->_tuple($rule_x);

    foreach my $rule_z ( @{$s_an} ) {

        if ( !$rule_z->get('DST_IP')->gt( $rule_x1->get('DST_IP') ) ) {

            #is Z between X and Y?
            if ( ( $rule_z->get('LINE')->number() >= $rule_x->get('LINE')->number() )
                && ( $rule_z->get('LINE')->number() <= $rule_y->get('LINE')->number() ) )
            {

                # Zd intersect Xp?
                if ( $rule_z->intersects($rule_x1) ) {

                    # Xp ! contain Zd
                    if ( !$rule_z->contained_by($rule_x1) ) {
                        return undef;
                    }
                }
            }
        }
        else {

     # $rule_z is greater than $rule_x1 therefore rule_x and rule_z are disjoint
            last;
        }
    }

    return 1;
}

# Given rule X, Y, where X precedes Y in the ACL
# a is the action type of the rule
# if X contains Y then Y can be removed
# if Y contains X then X can be removed if there are no rules Z
# in $s_an that intersect X and exist between X and Y in the ACL

sub _redundant {
    my ( $self, $s_a, $s_an ) = @_;

    # $s_a = ARRAY ref of rules of action a to be validated
    # $s_an = ARRAY ref of rules of action !a
    # $s_a and $s_an are sorted by ascending and must be readonly

    # iterate over rules of action a
    for ( my $x = 0 ; $x != scalar( @{$s_a} ) ; $x++ ) {

        # $rule_x1 is rule_x with layer 3 and 4 properties only
        my $rule_x = $s_a->[$x];

        #skip check if rule_x is already being removed
        next if $rule_x->has_defined('REMOVE');

        # remove non layer 3/4 rule properties
        my $rule_x1 = $self->_tuple( $s_a->[$x] );

        for ( my $y = $x + 1 ; $y != scalar( @{$s_a} ) ; $y++ ) {

            my $rule_y = $s_a->[$y];

            #skip check if a rule_x made more than one rule_y redundant
            next if $rule_y->has_defined('REMOVE');

            if ( !$rule_y->get('DST_IP')->gt( $rule_x->get('DST_IP') ) ) {

                # $rule_x comes before rule_y in the rule array
                # therefore x might contain y

                if ( $rule_y->contained_by($rule_x1) ) {

                    # rule_x is before rule_y in the rule set so remove rule_y
                    if ( $rule_x->get('LINE')->number() <= $rule_y->get('LINE')->number() )
                    {
                        $rule_y->set( 'REMOVE', Farly::Value::String->new('RULE') );
                        $self->_log_remove( $rule_x, $rule_y );
                    }
                    else {

                        # rule_y is actually after rule_x in the rule set
                        if ( $self->_can_remove( $rule_y, $rule_x, $s_an ) ) {
                            $rule_y->set( 'REMOVE', Farly::Value::String->new('RULE') );
                            $self->_log_remove( $rule_x, $rule_y );
                        }
                    }
                }
            }
            else {

            # rule_y DST_IP is greater than rule_x DST_IP therefore rule_x can't
            # contain rule_y or any rules after rule_y (they are disjoint)
                last;
            }
        }
    }
}

sub _remove {
    my ( $self, $a_ref ) = @_;

    my $remove = Farly::Object::List->new();

    foreach my $rule (@$a_ref) {
        if ( $rule->has_defined('REMOVE') ) {
            $remove->add($rule);
        }
    }

    return $remove;
}

sub _keep {
    my ( $self, $a_ref ) = @_;

    my $keep = Farly::Object::List->new();

    foreach my $rule (@$a_ref) {
        if ( !$rule->has_defined('REMOVE') ) {
            $keep->add($rule);
        }
    }

    return $keep;
}

sub _log_remove {
    my ( $self, $keep, $remove ) = @_;

    if ( $self->_is_verbose() ) {
        print " ! ";
        $self->_template->as_string($keep);
        print "\n";
        $self->_template->as_string($remove);
        print "\n";
    }
}

sub _do_sort {
    my ( $self, $list ) = @_;

    my @sorted;

    if ( $self->_mode eq 'L4' ) {
        @sorted = sort _ascending_l4 $list->iter();
    }
    elsif ( $self->_mode eq 'L3' ) {
        @sorted = sort _ascending_l3 $list->iter();
    }
    elsif ( $self->_mode eq 'ICMP' ) {
        @sorted = sort _ascending_icmp $list->iter();
    }
    else {
        confess "mode error";
    }

    return \@sorted;
}

sub _optimize {
    my ($self) = @_;

    

    my $permits = $self->_do_search( $self->p_action );
    my $denies  = $self->_do_search( $self->d_action );

    my @arr_permits = sort _ascending_LINE $permits->iter();
    my @arr_denys   = sort _ascending_LINE $denies->iter();

    # find permit rules that contain deny rules
    # which are defined further down in the rule set
    $log->info("Checking for deny rule inconsistencies...");
    $self->_inconsistent( \@arr_permits, \@arr_denys );

    # create a new list of deny rules which are being kept
    $denies = $self->_keep( \@arr_denys );

    # the consistent deny list sorted by LINE again
    @arr_denys = sort _ascending_LINE $denies->iter();

    # find deny rules which contain permit
    # rules further down in the rule set
    $log->info("Checking for permit rule inconsistencies...");
    $self->_inconsistent( \@arr_denys, \@arr_permits );

    # create the list of permit rules which are being kept
    $permits = $self->_keep( \@arr_permits );

    # sort the rule in ascending order
    my $aref_permits = $self->_do_sort($permits);
    my $aref_denys   = $self->_do_sort($denies);

    $log->info("Checking for permit rule redundancies...");
    $self->_redundant( $aref_permits, $aref_denys );

    $permits = $self->_keep($aref_permits);

    # sort the permits again
    $aref_permits = $self->_do_sort($permits);

    $log->info("Checking for deny rule redundancies...");
    $self->_redundant( $aref_denys, $aref_permits );

}

1;
__END__
=head1 NAME

Farly::Rule::Optimizer - Optimize an expanded firewall rule set

=head1 SYNOPSIS

  use Farly;
  use Farly::Rule::Expander;
  use Farly::Rule::Optimizer;

  my $file = "test.cfg";
  my $importer = Farly->new();
  my $container = $importer->process('ASA',$file);

  my $rule_expander = Farly::Rule::Expander->new( $container );
  my $expanded_rules = $rule_expander->expand_all();  

  my $search = Farly::Object->new();
  $search->set( 'ID', Farly::Value::String->new('outside-in') );
  my $search_result = Farly::Object::List->new();
  $expanded_rules->matches( $search, $search_result );

  my $optimizer = Farly::Rule::Optimizer->new( $search_result );
  $optimizer->verbose(1);
  $optimizer->run();
  my $optimized_ruleset = $optimizer->optimized();

  my $template = Farly::Template::Cisco->new('ASA');
  foreach my $rule ( $optimized_ruleset->iter ) {
    $template->as_string( $rule );
    print "\n";
  }

=head1 DESCRIPTION

Farly::Rule::Optimizer finds duplicate and contained firewall rules in an 
expanded rule set.

Farly::Rule::Optimizer stores the list of optimized rules, as well as the list 
of rule entries which can be removed from the rule set without effecting the
traffic filtering properties of the firewall.

The 'optimized' and 'removed' rule sets are expanded rule entries and may
not correspond to the actual configuration on the device.

To view Farly::Rule::Optimizer actions and results with Log4perl, set the logging adapter to Log::Any::Adapter::Log4perl and 
add the following to your Log4perl configuration:

 log4perl.logger.Farly.Optimizer=INFO,Screen
 log4perl.appender.Screen=Log::Log4perl::Appender::Screen 
 log4perl.appender.Screen.mode=append
 log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
 log4perl.appender.Screen.layout.ConversionPattern=%d %p> %F{1}:%L %M - %m%n

See L<Log::Any::Adpater> and L<Log::Any::Adapter::Log4perl> for details.
Logged rules are currently displayed in Cisco ASA format.

=head1 METHODS

=head2 new()

The constructor. A single expanded rule list is required.

  $optimizer = Farly::Rule::Optimizer->new( $expanded_rules<Farly::Object::List> );

=head2 verbose()

Have the optimizer display analysis results in Cisco ASA format

	$optimizer->verbose(1);

=head2 run()

Run the optimizer.

	$optimizer->run();

=head2 set_p_action()

Change the default permit string. The default permit string is "permit."

	$optimizer->set_p_action("accept");

=head2 set_d_action()

Change the default deny string. The default deny string is "deny."

	$optimizer->set_d_action("drop");

=head2 set_icmp()

Set the optimizer to optimize ICMP rules

	$optimizer->set_icmp();

=head2 set_l3()

Set the optimizer to optimize layer three rules, which does not include
TCP, UDP or ICMP rules.

	$optimizer->set_l3();

=head2 optimized()

Returns a Farly::Object::List<Farly::Object> container of all expanded firewall
rules, excluding duplicate and overlapping rule objects, in the current Farly
firewall model.

  $optimized_ruleset = $optimizer->optimized();

=head2 removed()

Returns a Farly::Object::List<Farly::Object> container of all duplicate and 
overlapping firewall rule objects which could be removed.

  $remove_rules = $optimizer->removed();

=head1 ACKNOWLEDGEMENTS

Farly::Rule::Optimizer is based on the "optimise" algorithm in the following
paper:

Qian, J., Hinrichs, S., Nahrstedt K. ACLA: A Framework for Access
Control List (ACL) Analysis and Optimization, Communications and 
Multimedia Security, 2001

=head1 COPYRIGHT AND LICENCE

Farly::Rule::Optimizer
Copyright (C) 2012  Trystan Johnson

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
