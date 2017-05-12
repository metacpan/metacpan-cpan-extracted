use strict;
use warnings;

use English qw($OS_ERROR);
use Config::IniFiles;
use Time::HiRes qw(usleep);
use Cwd;
my $path = $ARGV[0];

exit if not ($path);

# $path = '../etc/Hyper/Control/Flow/SecureAccessSSL/FCreateAccount.ini';

my $WARN = 0;

local $SIG{__WARN__} = sub { $WARN++; warn @_ };

my $config = Config::IniFiles->new(
            -file => $path,
        ) or die "can't read INI file >$path< $OS_ERROR", 
        @Config::IniFiles::errors;


if ($path=~m{ (\\|/) Flow (\\|/) }xms) {
    run_checks( $config, 
        qw(
        step_START 
        step_END 
        step_transitions
        step_controls
        step_transition_content
        step_content
        step_action
        control_class
        control_template        
        ) )
}
elsif ($path=~m{ (\\|/) Container (\\|/) }xms) {
    run_checks( $config, 
        qw(
        step_START 
        step_END 
        step_transitions
        step_controls
        step_transition_content
        step_content
        step_action
        control_class
        control_template
        ) )
}

usleep 10;
print "# $WARN errors found\n";

### Subs follow here...

sub run_checks {
    my $config = shift;
    my @checks_from = @_;
    foreach my $check (@checks_from) {
        main->can($check)->( $config );
    }
}

=pod 

=head2 step_START

Checks whether there is a [Step START].

=cut 

sub step_START {
    my $config = shift;
    warn "ERROR: [Step START] missing\n" if not 
        $config->SectionExists('Step START');
}

=pod

=head2 step_END

Checks whether there is a [Step END]. 

=cut

sub step_END {
    my $config = shift;
    warn "ERROR: [Step END] missing\n" if not 
        $config->SectionExists('Step END');    
}

=pod

=head2 step_content

Checks whether steps have only action|controls as parameters

=cut 

sub step_content {
    my $config = shift;

    my @steps_from = ();
    for my $step ($config->GroupMembers('Step')) {
        my $name = $step;
        $name =~s{\A Step \s}{}xms;
        if ($name !~m{\s}) {
            push @steps_from, $name;
        }
    }

    for my $step (@steps_from) {
        my @parameters = $config->Parameters("Step $step") 
            ? $config->Parameters("Step $step") 
            : ();
        
        my @invalid = grep { $_ !~m{ \A (action|controls) \Z }xms } @parameters;
        warn "ERROR: Invalid parameters in [Step $step]: "
            . join(', ',  @invalid)
            . "\n"
            if (@invalid);
    }
}

=pod

=head2 step_transition_content

Check whether transitions only have 'condition' as parameters

=cut

sub step_transition_content {
    my $config = shift;

    # build up steps_of hash and @transitions_from list 
    # with all steps and all transitions
    my @transitions_from = ();
    for my $step ($config->GroupMembers('Step')) {
        my $name = $step;
        $name =~s{\A Step \s}{}xms;
        if ($name =~m{\s}) {
            my ($from, $to) = split m{\s} , $name;
            push @transitions_from, $name; 
        } 
    }

    for my $transition (@transitions_from) {
        my @parameters = $config->Parameters("Step $transition") 
            ? $config->Parameters("Step $transition") 
            : ();
        
        my @invalid = grep { $_ ne 'condition' } @parameters;
        warn "ERROR: Invalid transition parameters in [Step $transition]: "
            . join(', ',  @invalid) 
            . "\n"
            if (@invalid);
    }
}

=pod

=head2 step_transitions

Checks whether all steps (except END) have valid transitions

=cut 

sub step_transitions {
    my $config = shift;

    # build up steps_of hash and @transitions_from list 
    # with all steps and all transitions
    my %steps_of = ();
    my @transitions_from = ();
    for my $step ($config->GroupMembers('Step')) {
        my $name = $step;
        $name =~s{\A Step \s}{}xms;
        if ($name =~m{\s}) {
            my ($from, $to) = split m{\s} , $name;
            push @transitions_from, { from => $from, to => $to }; 
        } 
        else {
            $steps_of{ $name } = 1;
        }
    }
    
    # check wheter all transitions have a valid source and destination 
    for my $transition (@transitions_from) {
        warn "ERROR: Non-existant transition source $transition->{ from } "
            . "in [Step $transition->{ from } $transition->{ to }]\n"
            if not exists $steps_of{ $transition->{ from } }; 
        warn "ERROR: Non-existant transition destination $transition->{ to } "
            . "in [Step $transition->{ from } $transition->{ to }]\n"
            if not exists $steps_of{ $transition->{ to } } 
    }   
    
    # check whether all steps (except END) are transition sources
    my %from_steps_of = %steps_of;
    for my $transition (@transitions_from) {
        delete $from_steps_of{ $transition->{ from } };
        delete $from_steps_of{ END };
    }
    warn "ERROR: Steps without transition destination: " 
        . join ( ', ' , sort keys %from_steps_of  ) 
        . "\n"
        if (%from_steps_of);

    # check whether all steps (except START) are transition destinations
    my %to_steps_of = %steps_of;
    for my $transition (@transitions_from) {
        delete $to_steps_of{ $transition->{ to } };
        delete $to_steps_of{ START };
    }
    warn "ERROR: Steps without transition source: " 
        . join ( ', ' , sort keys %to_steps_of  ) 
        . "\n"
        if (%to_steps_of)
}

=pod

=head2 step_controls

Checks whether steps only reference existant controls

=cut

sub step_controls {
    my $config = shift;
    my %controls_of = ();
    foreach my $control ($config->GroupMembers('Control')) {
        $control =~s{\A Control \s }{}xms;
        # skip validators and the like
        next if ($control =~m{ \s }xms );
        $controls_of{ $control } = 1;
    }
    for my $step ($config->GroupMembers('Step')) {
        my $name = $step;
        $name =~s{\A Step \s}{}xms;
        next if ($name =~m{\s});
        my @controls_from = defined $config->val( "Step $name", 'controls')
            ? $config->val( "Step $name", 'controls')
            : ();
        
        foreach my $control(@controls_from) {
            warn "ERROR: Non-existant control $control included in [Step $name]\n"
                if not exists $controls_of{ $control };
        }
    }
}

=pod

=head2 control_class

Checks whether all class="FOO" classes defined for controls can be loaded

=cut

sub control_class {
    my $config = shift;
    foreach my $control ($config->GroupMembers('Control')) {
        $control =~s{\A Control \s }{}xms;
        # skip validators and the like
        next if ($control =~m{ \s }xms );
        my $class = $config->val("Control $control", 'class');
        $class =~s {\.}{::}xmsg;
        $class = "Hyper::Control::$class";
        warn "ERROR: cannot load class $class for [Control $control]: $@\n"
            if not eval "require $class";
    }
}

=pod

=head2 control_template

Checks whether all template="FOO" templates exist

=cut

sub control_template {
    my $config = shift;
    my $cwd = cwd;
    foreach my $control ($config->GroupMembers('Control')) {
        $control =~s{\A Control \s }{}xms;
        # skip validators and the like
        next if ($control =~m{ \s }xms );
        my $template = $config->val("Control $control", 'template');
        next if not $template;
        warn "ERROR: Non-existant template=$template specified for [Control $control]"
            if not -e "var/$template";
    }
}

=pod

=head2 step_action

Checks whether all action targets are valid controls

=cut

# TODO use parser for determining controls 

sub step_action {
    my $config = shift;
    my %controls_of = (
        this => 1,
    );
    foreach my $control ($config->GroupMembers('Control')) {
        $control =~s{\A Control \s }{}xms;
        # skip validators and the like
        next if ($control =~m{ \s }xms );
        $controls_of{ $control } = 1;
    }
    for my $step ($config->GroupMembers('Step')) {
        my $name = $step;
        $name =~s{\A Step \s}{}xms;
        next if ($name =~m{\s});
        my @action_from = defined $config->val( "Step $name", 'action')
            ? $config->val( "Step $name", 'action')
            : ();
        
        foreach my $action(@action_from) {
            my ($target, $source) = split m{=}, $action || $action;
            
            # only try if our target looks like identifier.identifier
            if ($target =~ s{ \A ([^\.]+) \. .+  \Z }{$1}xms ) {          
                warn "ERROR: Non-existant target $target specified in action $action in [Step $name]\n"
                    if not exists $controls_of{ $target };
            }    

            # only try if our sourcelooks like identifier.identifier            
            if ($source =~ s{ \A ([A-z][A-z0-9]+) \. .+ \Z}{$1}xms) {
                warn "ERROR: Non-existant source $source specified in action $action in [Step $name]\n"
                    if not exists $controls_of{ $source };               
            }
        }
    }
}
