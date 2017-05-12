package DataEcho;

# Copyright (c) 2003 by Vsevolod (Simon) Ilyushchenko. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
# The code is based on the -PHP project (http://amfphp.sourceforge.net/)


=head1 NAME
    DataEcho
        
==head1 DESCRIPTION    

    Service class used in conjusction with basic.pl
    
    All FLAP service classes must define the method table, where the user can supply optional description and return type.

==head1 CHANGES

Sun Apr  6 14:24:00 EST 2003
Created after AMF-PHP.

=cut

sub new
{
    my ($proto)=@_;
    my $self={};
    bless $self, $proto;
    return $self;
}


sub methodTable
{
    return {
        "echoNormal" => {
            "description" => "Echoes the passed argument back to Flash (no need to set the return type)",
            "access" => "remote", # available values are private, public, remote
        },
        "echoDate" => {
            "description" => "Echoes a Flash Date Object (the returnType needs setting)",
            "access" => "remote", # available values are private, public, remote
            "returns" => "date"
        },
        "echoXML" => {
            "description" => "Echoes a Flash XML Object (the returnType needs setting)",
            "access" => "remote", # available values are private, public, remote
            "returns" => "xml"
        }
    };
}

sub echoNormal
{
    my ($self, $data) = @_;
    return $data;
}
sub echoDate
{
    my ($self, $data) = @_;
    return $data;
}
sub echoXML
{
    my ($self, $data) = @_;
    return $data;
}

1;
