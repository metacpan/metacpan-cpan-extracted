package Games::Lacuna::Task::ActionProto;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task);

use List::Util qw(max);
use Try::Tiny;
use Games::Lacuna::Task::Utils qw(name_to_class class_to_name);

sub run {
    my ($self) = @_;
    
    my $task_name = shift(@ARGV);
    my $task_class = name_to_class($task_name);
    
    if (! defined $task_name) {
        say "Missing command";
        $self->global_usage();
    } elsif ($task_name ~~ [qw(help ? --help -h -? --usage usage)]) {
        $self->global_usage();
    } elsif (! ($task_class ~~ [$self->all_actions()])) {
        say "Unknown command '$task_name'";
        $self->global_usage();
    } else {
        $ARGV[0] = '--help'
            if defined $ARGV[0] && $ARGV[0] eq 'help';
        
        my ($ok,$error) = $self->load_action($task_class);
        
        if (! $ok) {
            $self->log('error',$error);
        } else {
            my $configdir;
            my $loglevel;
            my $help;
            my $debug;
            
            my $opt_parser = Getopt::Long::Parser->new( config => [ qw( no_auto_help pass_through ) ] );
            $opt_parser->getoptions( 
                "configdir=s"   => \$configdir,
                "debug"         => \$debug,
                "loglevel=s"    => \$loglevel,
                "help|usage|?"  => \$help,
            );
            
            $self->loglevel($loglevel)
                if $loglevel;
            
            $self->configdir($configdir)
                if defined $configdir && $configdir ne '';
            
            $self->debug($debug)
                if defined $debug;

            my $task_config = $self->client->task_config($task_name);
            
            if ($help) {
                $self->task_usage($task_class);
            } else {
                eval {
                    my $pa = $task_class->process_argv($task_config);
                        
                    my $object = $task_class->new(
                        ARGV        => $pa->argv_copy,
                        extra_argv  => $pa->extra_argv,
                        #usage       => $pa->usage,
                        %{ $task_config },          # explicit params to ->new
                        %{ $pa->cli_params },       # params from CLI
                    );
                    
                    $self->log('notice',("=" x ($Games::Lacuna::Task::Constants::SCREEN_WIDTH - 8)));
                    $self->log('notice',"Running task %s for empire %s",$task_name,$self->empire_name);
                    $object->execute;
                    $self->log('notice',("=" x ($Games::Lacuna::Task::Constants::SCREEN_WIDTH - 8)));
                };
                if (my $error = $@) {
                    $error =~ s/\n.+//s;
                    $self->log('error',$error);
                    $self->task_usage($task_class);
                    return;
                }
            }
        }
    }
    
    return;
}


sub _usage_attributes {
    my ($self,$class) = @_;
    
    my @attributes;
    
    my $meta = $class->meta;
    foreach my $attribute ($meta->get_all_attributes) {
        next
            if $attribute->does('NoGetopt');
        
        my @names;
        if ($attribute->can('cmd_flag')) {
            push(@names,$attribute->cmd_flag);
        } else {
            push(@names,$attribute->name);
        }
        
        if ($attribute->can('cmd_aliases')
            && $attribute->cmd_aliases) {
            push(@names, @{$attribute->cmd_aliases});
        }
        my $attribute_name = join(' ', map { (length($_) == 1) ? "-$_":"--$_" } @names);
        
        push(@attributes,[$attribute_name,$attribute->documentation]);
    }
    
    @attributes = sort { $a->[0] cmp $b->[0] } @attributes;
    
    return _format_list(@attributes);
}

sub _usage_header {
    my ($self,$command) = @_;
    
    $command ||= 'command';
    
    my $caller = Path::Class::File->new($0)->basename;
    
    return <<USAGE_HEADER;
usage: 
    $caller $command [long options...]
    $caller help
    $caller $command --help
USAGE_HEADER
}

sub task_usage {
    my ($self,$task_class) = @_;
    
    my $task_name = class_to_name($task_class);
    
    my $usage_header = $self->_usage_header($task_name);
    my $short_description = $task_class->description;
    my $options = $self->_usage_attributes($task_class);
    
    say <<USAGE_ACTION;
$usage_header
short description:
    $short_description

options:
$options
USAGE_ACTION

    return;
}

sub global_usage {
    my ($self) = @_;
    
    my @commands;
    push(@commands,['help','Prints this usage information']);
    
    foreach my $task_class ($self->all_actions()) {
        my ($ok,$error) = $self->load_action($task_class);
        next
            unless $ok;
        my $task_command = class_to_name($task_class);
        my $meta = $task_class->meta;
        my $description = $task_class->description;
        my $no_automatic = $meta->can('no_automatic') ? $meta->no_automatic : 0;
        $description .= " [Manual]"
            if $no_automatic;
        push(@commands,[$task_command,$description]);
    }
    
    @commands = sort { $a->[0] cmp $b->[0] } @commands;
    
    my $global_options = $self->_usage_attributes($self);
    my $available_commands = _format_list(@commands);
    my $usage_header = $self->_usage_header();
    
    say <<USAGE;
$usage_header
global options:
$global_options

available commands:
$available_commands
USAGE

    return;
}

sub _format_list {
    my (@list) = @_;
    
    my $max_length = max(map { length($_->[0]) } @list);
    my $description_length = $Games::Lacuna::Task::Constants::SCREEN_WIDTH - $max_length - 7;
    my $prefix_length = $max_length + 5 + 1;
    my @return;
    
    foreach my $command (@list) {
        my $description = $command->[1];
        $description .= " [Manual]"
            if $command->[2];
        my @lines = _split_string($description_length,$description);
        push (@return,sprintf('    %-*s  %s',$max_length,$command->[0],shift(@lines)));
        while (my $line = shift (@lines)) {
            push(@return,' 'x $prefix_length.$line);
        }
    }
    return join("\n",@return);
}

sub _split_string {
    my ($maxlength, $string) = @_;
    
    return $string 
        if length $string <= $maxlength;

    my @lines;
    while (length $string > $maxlength) {
        my $idx = rindex( substr( $string, 0, $maxlength ), q{ }, );
        last unless $idx >= 0;
        push @lines, substr($string, 0, $idx);
        substr($string, 0, $idx + 1) = q{};
    }
    push @lines, $string;
    return @lines;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
