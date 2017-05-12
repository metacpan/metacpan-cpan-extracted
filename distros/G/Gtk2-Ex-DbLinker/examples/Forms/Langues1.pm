package Forms::Langues1;

use strict;
use warnings;

# use DBI;

use Gtk2::Ex::DbLinker::Form;
use Gtk2::Ex::DbLinker::Datasheet;
use Gtk2::Ex::DbLinker::DbiDataManager;

sub new {

    my ( $class, $href ) = @_;

    my $self = {
        gladefolder => $$href{gladefolder},
        dbh         => $$href{dbh},
    };

    my $builder = Gtk2::Builder->new();
    $builder->add_from_file( $self->{gladefolder} . "/langues.bld" )
      or die "Couldn't read  langues.bld";

    $builder->connect_signals($self);

    my $combodata = Gtk2::Ex::DbLinker::DbiDataManager->new(
        dbh          => $self->{dbh},
        primary_keys => ["countryid"],
        sql          => {
            select   => "countryid, country",
            from     => "countries",
            order_by => "country",
            where    => "1=1",
        },
    );

    Gtk2::Ex::DbLinker::Form->add_combo(
        data_manager => $combodata,
        id           => 'countryid',
        builder      => $builder,
    );

    my $treeview = Gtk2::TreeView->new();
    my $lstdata  = Gtk2::Ex::DbLinker::DbiDataManager->new(
        dbh          => $self->{dbh},
        primary_keys => ["langues.langid"],
        sql          => {
            select => "langues.langid as langid, langues.langue as langue",
            from =>
              "langues inner join speaks on langues.langid = speaks.langid",
            where       => "speaks.countryid =?",
            bind_values => [0],
        },
    );

    $self->{langues} = Gtk2::Ex::DbLinker::Datasheet->new(
        treeview => $treeview,
        fields =>
          [ { name => "langid", renderer => "hidden" }, { name => "langue" }, ],
        data_manager => $lstdata,
    );

    my $ctrl_to = $builder->get_object('alignment1');

    $ctrl_to->add($treeview);

    $self->{langues}->update;

    $builder->get_object("vbox4")->show_all;

    $builder->get_object("mainwindow")
      ->signal_connect( "destroy", \&gtk_main_quit );

    bless $self, $class;

}

sub on_countryid_changed {
    my ( $lst, $self ) = @_;

    my $iter = $lst->get_active_iter;
    return unless ($iter);
    my $value = $lst->get_model->get( $iter, 0 );
    print "on_countryid_changed: ", $value, "\n";
    $self->{langues}->get_data_manager->query(
        where       => "speaks.countryid=?",
        bind_values => [$value]
    );
    $self->{langues}->update;
}

sub gtk_main_quit {
    my ($w) = @_;
    Gtk2->main_quit;
}

1;
