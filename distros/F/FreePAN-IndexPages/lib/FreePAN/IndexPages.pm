package FreePAN::IndexPages;
use FreePAN::Plugin -Base;
use mixin 'FreePAN::Installer';
use IO::All;
use SVK;
use SVK::XD;
our $VERSION = '0.02';

const class_id => 'indexpages';
const config_file => 'config/indexpages.yaml';

# module, repository, mirror

sub register {
    my $reg = shift;
    $reg->add(command => 'create_module_index',
              description => 'Create Module index page');
    $reg->add(command => 'create_repository_index',
              description => 'Create Repository index page');
}

sub handle_create_repository_index {
    my @repos = map { $_->filename } io($self->hub->config->repos_base)->all_dirs;
    my $output = $self->hub->template->process('repositories.html',repos => \@repos);
    $output > io->catfile($self->hub->config->document_root,"repositories.html")->assert;
}

sub handle_create_module_index {
    die("You don't have repos_base directory\n")
        unless -d $self->hub->config->repos_base;
    my %repos = sub {
        map {
            $_->filename , $_->name
        } io($self->hub->config->repos_base)->all_dirs;
    }->();
    my $output;
    my $xd = SVK::XD->new(depotmap => \%repos);
    my $svk = SVK->new(xd => $xd, output => \$output);
    my %author_of;
    for my $author (keys %repos) {
        $svk->ls("/$author/");
        $author_of{$_} = $author for map {s{/$}{};$_} grep !/^\s*$/,split/\n+/,$output;
    }
    $output = $self->hub->template->process('modules.html',
                                            modules => \%author_of,
                                            hub => $self->hub);
    $output > io->catfile($self->hub->config->document_root,"modules.html")->assert
}

__DATA__
__config/indexpages.yaml__
document_root: /var/freepan/apache2/htdocs
__templates/modules.html__
<html>
    <title>FreePAN Module Index</title>
    <body>
    <h1>FreePAN Module Index</h1>
    <ul>
    [%- FOREACH key = modules.keys %]
    <li><a href="[% hub.config.svn_domain_name %]/[% modules.$key %]/[% key %]">[% key %]</a></li>
    [% END -%]
    </ul>
    </body>
</html>
__templates/repositories.html__
<html>
    <title>FreePAN Repositories Index</title>
    <body>
    <h1>FreePAN Repositories Index</h1>
    <ul>
    [%- FOREACH repo = repos %]
    <li><a href="[% hub.config.svn_domain_name %]/[% repo %]">[% repo %]</a></li>
    [% END -%]
    </ul>
    </body>
</html>
