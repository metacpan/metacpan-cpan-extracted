package Koha::Contrib::Tamil::Logger;
# ABSTRACT: Base class pour logger
$Koha::Contrib::Tamil::Logger::VERSION = '0.050';

use Moose;
use Modern::Perl;
use FindBin qw( $Bin );
use Log::Dispatch;
use Log::Dispatch::Screen;
use Log::Dispatch::File;



has log_filename => (
    is => 'rw',
    isa => 'Str',
    default => "./koha-contrib-tamil.log",
);

has log => (
    is => 'rw',
    isa => 'Log::Dispatch',
    lazy => 1,
    default => sub { 
        my $self = shift;
        my $log = Log::Dispatch->new();
        $log->add( Log::Dispatch::Screen->new(
            name      => 'screen',
            min_level => 'notice',
        ) );
        $log->add( Log::Dispatch::File->new(
            name      => 'file1',
            min_level => 'debug',
            filename  => $self->log_filename, 
        ) );
        return $log;
    }
);



no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Logger - Base class pour logger

=head1 VERSION

version 0.050

=head1 SYNOPSYS

 package MonModule
 use Moose;

 extends qw/ Koha::Contrib::Tamil::Logger /;

 sub foo {
    my $self = shift;
    $self->info("Sera écrit dans le fichier uniquement");
    $self->warning("Sera écrit dans le fichier ET envoyé à l'écran");
 }
 1;

 package Main;

 use MonModule;

 my $mon_module = MonModule->new( filename => 'mon_module.log');
 $mon_module->foo();

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
