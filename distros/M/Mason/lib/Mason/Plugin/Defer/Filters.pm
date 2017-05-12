package Mason::Plugin::Defer::Filters;
$Mason::Plugin::Defer::Filters::VERSION = '2.24';
use Mason::PluginRole;

method Defer () {
    Mason::DynamicFilter->new(
        filter => sub {
            $self->m->defer( $_[0] );
        }
    );
}

1;
