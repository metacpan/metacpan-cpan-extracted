use 5.006;    # our
use strict;
use warnings;

package KENTNL::WLTest;

our $VERSION = '0.001000';

# ABSTRACT: A Testing container for warnloggers

# AUTHORITY

use Exporter qw();
*import = \&Exporter::import;

our @EXPORT_OK  = qw( with_env );
our $ENV_PREFIX = 'T_LCWL';
our $GRP_PREFIX = 'T_LCWL_GROUP';

use Term::ANSIColor qw( colorstrip );
use Log::Contextual qw{ with_logger };

sub with_env {
    my (%local_env) = @_;
    my $instance = bless { local_env => {%local_env} }, __PACKAGE__;
    return $instance;
}

sub with_warner {
    my ( $self, %cargs ) = @_;
    my $clone = bless { %{$self} }, __PACKAGE__;
    $clone->{cargs} = {%cargs};
    return $clone;
}

sub run {
    my ( $self, $runcode ) = @_;
    my $clone = bless { %{$self} }, __PACKAGE__;
    my $hook = sub {
        require Log::Contextual::WarnLogger::Fancy;
        my $instance =
          Log::Contextual::WarnLogger::Fancy->new( $clone->{cargs} );
        my $capture = '';
        with_logger $instance => sub {
            local $SIG{__WARN__} = sub { $capture .= $_[0]; };
            $runcode->($instance);
        };
        return $capture;
    };
    my $code = '';
    for my $term (qw( TRACE DEBUG INFO WARN ERROR FATAL UPTO )) {
        if (   exists $ENV{ $ENV_PREFIX . '_' . $term }
            or exists $clone->{local_env}->{$term} )
        {

            $code .=
                "local \$ENV{\"${ENV_PREFIX}_${term}\"}"
              . " = \$clone->{local_env}->{'$term'};\n"
              if exists $clone->{local_env}->{$term};

            $code .= "delete local \$ENV{\"${ENV_PREFIX}_${term}\"};\n"
              if not exists $clone->{local_env}->{$term};
        }
        if (   exists $ENV{ $GRP_PREFIX . '_' . $term }
            or exists $clone->{local_env}->{"G$term"} )
        {

            $code .=
                "local \$ENV{\"${GRP_PREFIX}_${term}\"}"
              . " = \$clone->{local_env}->{'G$term'};\n"
              if exists $clone->{local_env}->{"G$term"};

            $code .= "delete local \$ENV{\"${GRP_PREFIX}_${term}\"};\n"
              if not exists $clone->{local_env}->{"G$term"};
        }

    }
    for my $term (qw( GTRACE GDEBUG GINFO GWARN GERROR GFATAL GUPTO )) {
        next
          if not exists $ENV{ $GRP_PREFIX . '_' . $term }
          and not exists $clone->{local_env}->{$term};

        $code .=
            "local \$ENV{\"${ENV_PREFIX}_${term}\"}"
          . " = \$clone->{local_env}->{'$term'};\n"
          if exists $clone->{local_env}->{$term};

        $code .= "delete local \$ENV{\"${ENV_PREFIX}_${term}\"};\n"
          if not exists $clone->{local_env}->{$term};
    }

    $code .= "\$hook->()\n";

    local $@;
    my $ret = eval $code;
    die $@ if $@;
    return $ret;

}

1;

