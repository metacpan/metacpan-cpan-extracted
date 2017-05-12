package Mason::Plugin::DefaultFilter::Compilation;

use Mason::PluginRole;

our $VERSION = '0.003'; # VERSION

around _handle_substitution => sub {
    my($orig,$self,$text,$filter_list) = @_;
    if (!defined $filter_list) {
        $filter_list = join q{,}, @{$self->interp->default_filters};
    } elsif ($filter_list eq 'N') {
        $filter_list = undef;
    }
    $self->$orig($text,$filter_list);
};

1;
