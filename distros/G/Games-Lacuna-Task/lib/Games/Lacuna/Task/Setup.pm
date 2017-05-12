package Games::Lacuna::Task::Setup;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
with qw(Games::Lacuna::Task::Role::Actions);

use Games::Lacuna::Task::Utils qw(class_to_name name_to_class);
use Term::ANSIColor qw(color);
use Term::ReadLine;
use Try::Tiny;
use YAML::Any qw(DumpFile);

has 'configfile' => (
    is              => 'rw',
    isa             => 'Path::Class::File',
    required        => 1,
);

sub run {
    my ($self) = @_;
    
    $self->sayline("=");
    
    $self->saycolor("bold cyan","Enter your empire name");
    my $empire_name = $self->readline("Empire name:",qr/.+/);
    $self->sayline();
    
    $self->saycolor("bold cyan","Enter your empire password (preferably your sitter passwort)");
    my $empire_password = $self->readline("Password:",qr/.+/);
    $self->sayline();
    
    $self->saycolor("bold cyan","Enter your e-mail address (required for e-mail notifications)");
    my $email = $self->readline("E-Mail:",qr/.+\@.+/);
    $self->sayline();
    
    $self->saycolor("bold cyan","Which tasks do you want to run regularly (e.g. every hour)");
    say "Do not select task that you want to run less frequently (e.g. only once a day)\n";
    
    my %selected_tasks;
    foreach my $task_class (sort $self->all_actions) {
        my ($ok,$error) = $self->load_action($task_class);
        
        next
            unless $ok;
        next
            if $task_class->meta->can('no_automatic')
            && $task_class->meta->no_automatic;
        
        my $task_name = class_to_name($task_class);
        
        $self->saycolor("magenta bold",$task_name);
        say $task_class->description;
        if ($self->readline("Select task (y/n):",qr/^[yn]$/i) =~ /^[yY]$/) {
            $selected_tasks{$task_name} = $task_class;
        }
    }
    
    $self->sayline();
    $self->saycolor("bold cyan","The following task parameters require some kind of manual setup");
    say "Please refer to the task documentation for details\n";
    
    while (my ($task_name,$task_class) = each %selected_tasks) {
        foreach my $attribute ($task_class->meta->get_all_attributes) {
            next
                if $attribute->does('NoGetopt');
            next
                unless $attribute->is_required;
            next
                if $attribute->is_lazy_build || $attribute->has_default;
            next
                if $attribute->name eq 'email';
            say color("magenta bold").$task_name.color("reset")." : Option '".$attribute->name."' needs manual setup.";
        }
    }
    
    $self->sayline();
    $self->saycolor("bold cyan","Config written to ".$self->configfile->stringify);
    say "You might want to customize the initial config file";
    
    my $config = {
        connect => {
            name    => $empire_name,
            password=> $empire_password,
        },
        global => {
            task    => [ keys %selected_tasks ],
            email   => $email,
        },
    };
    
    $self->sayline();
    $self->saycolor("bold cyan","Please add the following line to your crontab:");
    say "0 * * * *    lacuna_task\n";
    $self->saycolor("bold cyan","Optionally you can add other task that should be run less frequently e.g.");
    say "5 8 * * *    lacuna_run empire_report";
    
    DumpFile($self->configfile,$config);
    
    $self->sayline("=");
    
    return $config;
}

sub sayline {
    my ($self,$line) = @_;
    $line ||= '-';
    say $line x $Games::Lacuna::Task::Constants::SCREEN_WIDTH;
}

sub saycolor {
    my ($self,$color,$string) = @_;
    say color($color).$string.color("reset");
}

sub readline {
    my ($self,$prompt,$expect) = @_;
    
    state $term ||= Term::ReadLine->new();
    while (defined (my $response = $term->readline($prompt.' '))) {
        if (defined $expect) {
            return $response
                if $response =~ $expect;
        } else {
            return $response
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;