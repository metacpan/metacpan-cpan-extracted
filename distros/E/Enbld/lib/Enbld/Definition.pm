package Enbld::Definition;

use strict;
use warnings;

use Module::Load::Conditional qw/can_load/;

require Enbld::Error;

sub new {
    my $class = shift;
    my $name = shift;

    my $self = {
        defined => {
            DefaultArgument     =>  undef,
            DarwinArgument      =>  undef,

            AdditionalArgument  =>  undef,

            AllowedCondition    =>  undef,
            ArchiveName         =>  undef,
            CopyFiles           =>  undef,
            Dependencies        =>  undef,
            DistName            =>  undef,
            DownloadSite        =>  undef,
            Extension           =>  undef,
            Filename            =>  undef,
            IndexParserForm     =>  undef,
            IndexSite           =>  undef,
            PatchFiles          =>  undef,
            Prefix              =>  undef,
            URL                 =>  undef,
            SortedVersionList   =>  undef,
            Version             =>  undef,
            VersionList         =>  undef,
#           VersionCondition    =>  undef,
            VersionForm         =>  undef,
            WebSite             =>  undef,
           
            TestAction          =>  undef,

            CommandConfigure    =>  undef,
            CommandMake         =>  undef,
            CommandTest         =>  undef,
            CommandInstall      =>  undef,
        },
    };

    my $module = 'Enbld::Definition::' . ucfirst( $name );

    can_load( modules => { $module => 0 } ) or
        die( Enbld::Error->new( "no definition for target '$name'" ));

    bless $self, $module;

    $self->initialize;

    return $self;
}

sub initialize {

    # do nothing ... virtual method

}

sub parse {
    my $self = shift;

    require Enbld::Target::AttributeCollector;
    my $attributes = Enbld::Target::AttributeCollector->new;

    foreach my $attribute ( keys %{ $self->{defined} } ) {
        $attributes->add( $attribute, $self->{defined}{ $attribute } );
    }

    return $attributes;
}

1;

=pod

=head1 NAME

Enbld::Definition - stores target software' attributes.

=head1 SYNOPSIS

 require Enbld::Definition;

 my $attributes = Enbld::Definition->new( 'git' )->parse;

 $attributes->add( 'VersionCondition', '1.8.5' );

 $attributes->ArchiveName;  # git
 $attributes->Vesion;       # 1.8.5
 $attributes->URL;      # http://git-core.googlecode.com/files/git-1.8.5.tar.gz

=head1 DESCRIPTION

Enbld::Definition stores target software' attributes.

=head1 METHODS

=over 2

=item new

  my $def = Enbld::Definition->new( 'git' );

Returns a new definition object for target software.

The return value is a Enbld::Definition::[target software] object.

When the definition module of the target software specified as the argument does not exist, undef is returned.

=item parse

  my $def = Enbld::Definition->new( 'git' );
  my $attributes = $def->parse;
  $attributes->ArchiveName; # -> git
  $attributes->Extension;   # -> tar.gz

Returns a new attributes collector for target software.

The return value is a Enbld::Target::AttributeCollector object.

=back

=head1 COPYRIGHT

copyright 2013- Magnolia C<< <magnolia.k@me.com> >>.

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
