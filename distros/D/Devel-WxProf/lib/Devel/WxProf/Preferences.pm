package Devel::WxProf::Preferences;
use strict; use warnings;
use YAML qw(LoadFile Dump);
use Fcntl;
use IO::File;
use File::HomeDir;
use File::Basename qw(dirname);
use Class::Std::Fast;
use version; our $VERSION = qv(0.0.1);

my @DYNAMIC_PREFERENCES = qw(
    default_dir
);
my $APP_NAME = 'wxprofile';

my %default_dir_of      :ATTR(:name<default_dir>        :default<()>);
my %map_font_size_of    :ATTR(:name<map_font_size>      :default<11>);
my %map_font_file_of    :ATTR(:name<map_font_file>      :default<'Vera.ttf'>);

sub get_data_dir {
    my $data_dir = File::HomeDir->my_data() . "/.$APP_NAME";
    return $data_dir if -d ($data_dir);
    mkdir $data_dir and return $data_dir;
    return;
}

sub get_font_dir {
    return dirname(__FILE__ ). '/Font';
}

sub BUILD {
    my ($self, $ident, $arg_ref) = @_;
    my $data_dir = File::HomeDir->my_data();
    if (-d "$data_dir/.$APP_NAME" ) {
        if (-r "$data_dir/.$APP_NAME/dynamic_preferences") {
            my $data_ref = eval {
                LoadFile("$data_dir/.$APP_NAME/dynamic_preferences")
            } || {};
            for my $name (keys( %{ $data_ref })) {
                if (my $method = $self->can("set_$name")) {
                    $method->($self, $data_ref->{ $name });
                }
            }
        }
    }
}

sub save_dynamic_preferences {
    my $self = shift;
    my $data_ref = {};
    my $data_dir = File::HomeDir->my_data();
    if (! -d "$data_dir/.$APP_NAME" ) {
        mkdir "$data_dir/.$APP_NAME" or return;
    }
    return if ! -w "$data_dir/.wxprofile";

    for my $name (@DYNAMIC_PREFERENCES) {
        if (my $method = $self->can("get_$name")) {
              $data_ref->{ $name } = $method->($self);
        }
        else {
            warn "unknown preference $name"
        }
    }
    my $fh = IO::File->new("$data_dir/.$APP_NAME/dynamic_preferences.$$",
        O_CREAT | O_WRONLY | O_EXCL
    ) or return;
    $fh->print(Dump($data_ref)) or return;
    $fh->close() or return;
    rename "$data_dir/.$APP_NAME/dynamic_preferences.$$"
        , "$data_dir/.$APP_NAME/dynamic_preferences"
}

sub DEMOLISH {
    my ($self) = @_;
    $self->save_dynamic_preferences();
}

1;