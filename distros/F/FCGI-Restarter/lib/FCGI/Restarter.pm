package FCGI::Restarter;
use 5.008001;
use strict;
use Class::Accessor::Tiny qw( new poll_interval watch_file script onidle onaccept);
use FCGI;
our $VERSION = '0.12';
our @expect_file;
our %file;
our $restart_file = "/home/sites/combats.ru/web/start.pl";

my $STDIN_fileno =  fileno STDIN;
my $count;
my $start;
sub new_request{
    my $self = shift;
    -t STDIN && return FCGI::accept() >= 0;
    my $wait = 0;
    FCGI::finish() if $start;

    do {
        my @vector = ( '', '', '' );
        vec( $_, $STDIN_fileno, 1) = 1 for ( $vector[0] );

        my $found = select $vector[0], $vector[1], $vector[2], $self->get_poll_interval() ||5;
        if ( vec( $vector[0], $STDIN_fileno, 1 )){
            my $onaccept = $self->get_onaccept();
            $onaccept->() if ref $onaccept eq 'CODE';
            $wait = 1;
        }
        else {
            exit 1 if $found < 0 ;
            my $onidle = $self->get_onidle();
            $onidle->() if ref $onidle eq 'CODE';
        }
    }
    until( $wait  > 0);

    if ( ! if_modified ( $self ) ){
        $start = 1;
        return FCGI::accept()>=0;
    }
    my $restart_file = $self->get_script();
    exec "$restart_file";
};

my %watch_file;
sub if_modified{
    my $self = shift;
    if ( $start ){
        my $files = $self->get_watch_file();
        my $afiles =  ref $files ? $files : [ $files ];
        for ( @$afiles ){
            my ( $mtime ) = (stat $_)[9];
            if ( $mtime != $watch_file{ $_ }{mtime} ){
                return 1;
            }
        }
        return ! $files;
    }
    else {
        my $files = $self->get_watch_file();
        $files = [ $files ] if ! ref $files;
        for ( @$files ){
            my ( $mtime ) = (stat $_)[9];
            $watch_file{ $_ }{mtime} = $mtime;
        }
        return 0;
    }
}


1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

FCGI::Restarter - Restart FCGI process on the fly

=head1 SYNOPSIS

    use FCGI::Restarter;
    my $Reloader = FCGI::Restarter->new();
    $Reloader->set_script($0);
    $Reloader->set_watch_file( 
        [
        $0,                         # Look for modification of self
        $INC{ "Web/MyModule.pm"},   # Look for chaneg of some module
        "my config path",           # Look for changes in config
        ] );

    while( $Reloader->new_request()) { # Instead of (FCGI::accept() >= 0)
        my $q = CGI->new;
        
        # process request 

    }

=head1 DESCRIPTION

    FCGI::Restarter provide same functionality as FCGI plus it restart self if watch files changed in time.
    This additional function especially usefull in development enviroment.      

=head1 EXPORT

None by default.

=head1 NOTE
    
This module expected to work in UNIX like enviroment

=head1 SEE ALSO

    L<FCGI>

=head1 AUTHOR

Grishaev Anatoliy, E<lt>grian@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Grishaev Anatoliy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
