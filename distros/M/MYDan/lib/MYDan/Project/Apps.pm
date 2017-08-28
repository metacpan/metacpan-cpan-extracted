package MYDan::Project::Apps;

use strict;
use warnings;

$|++;

use MYDan::Util::OptConf;
my %o; BEGIN{ %o = MYDan::Util::OptConf->load()->dump('project');};

sub new
{
    my ( $class, %self ) =  @_;

    die "name undef" unless $self{name};
    bless \%self, ref $class || $class;
}

sub ctrl
{
    my ( $this, @ctrl, @result ) = @_;
    die "ctrl name undef" unless @ctrl;

    for my $ctrl ( @ctrl )
    {

        my $file = "$o{apps}/$this->{name}/$ctrl";
        die "$this->{name} $ctrl undef" unless -f $file;
        push @result, [ $ctrl, `cat '$file'`];
    }
    return @result;
}

1;
