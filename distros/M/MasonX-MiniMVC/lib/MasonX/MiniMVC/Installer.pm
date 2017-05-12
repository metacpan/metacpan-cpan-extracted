package MasonX::MiniMVC::Installer;

use strict;
use warnings;

use Cwd;

=head1 NAME

MasonX::MiniMVC::Installer -- Install a MiniMVC webapp

=head1 SYNOPSIS

    minimvc-install MyApp

=head1 DESCRIPTION

This module shouldn't be used directly.  Use the C<minimvc-install>
script instead.

=head1 INTERNAL DOCUMENTATION

=head2 install()

Install a new stub application.

=cut

sub install {
    my ($class, $app_name, @args) = @_;
    check_app_name($app_name);
    check_empty_dir(getcwd());
    build_dir_structure($app_name);
    write_stub_files($app_name);
}

=head2 check_app_name()

Checks that the application name supplied on the command line looks
like a Perl application name, i.e. matches \w+.  Dies if it's not OK.

=cut

sub check_app_name {
    my ($app_name) = @_;
    die "$app_name doesn't look like a suitable application name.\n" 
        unless $app_name =~ /^\w+$/;
}

=head2 check_empty_dir

Checks that the current directory is empty before installing MiniMVC.
Dies if it's not.

=cut

sub check_empty_dir {
    my ($dir) = @_;

    opendir DIR, $dir or die "Can't open current directory to check if it's empty: $!\n";
    my @files = grep !/^\.+$/, readdir(DIR);
    closedir DIR;

    if (@files) {
        die "Directory isn't empty.  Remove files and try again.\n";
    }
}

=head2 build_dir_structure()

Builds the directory structure for the application, i.e. lib/, t/, etc.

=cut

sub build_dir_structure {
    my ($app_name) = @_;

    print "Creating directory structure...\n";
    foreach my $dir (
        "lib/",
        "lib/$app_name/",
        "lib/$app_name/Controller/",
        "lib/$app_name/Model/",
        "t/",
        "view/",
        "view/sample/",
    ) {
        if (mkdir $dir) {
            print "  $dir\n";
        } else {
            warn "Couldn't make directory $dir: $!";
        }
    }
}

=head2 write_stub_files()

Writes stub files for the application, i.e. autohandler, dhandler,
sample controllers, etc.

=cut

sub write_stub_files {
    my ($app_name) = @_;

    print "Creating stub/sample files...\n";

    foreach my $file (
        {
            name => "dhandler",
            creator => \&_create_dhandler,
        },
        {
            name => "autohandler",
            creator => \&_create_autohandler,
        },
        {
            name => "index.mhtml",
            creator => \&_create_index,
        },
        {
            name => "lib/$app_name/Dispatcher.pm",
            creator => \&_create_dispatcher,
        },
        {
            name => "lib/$app_name/Controller/Sample.pm",
            creator => \&_create_controller_sample,
        },
        {
            name => "lib/$app_name/Model/Sample.pm",
            creator => \&_create_model_sample,
        },
        {
            name => "t/controller_sample.t",
            creator => \&_create_controller_sample_test,
        },
        {
            name => "t/model_sample.t",
            creator => \&_create_model_sample_test,
        },
        {
            name => "view/default.mhtml",
            creator => \&_create_view_default,
        },
        {
            name => "view/sample/default.mhtml",
            creator => \&_create_view_sample_default,
        },
        {
            name => ".htaccess",
            creator => \&_htaccess,
        },
        {
            name => "view/.htaccess",
            creator => \&_htaccess_deny,
        },
        {
            name => "lib/.htaccess",
            creator => \&_htaccess_deny,
        },
        {
            name => "t/.htaccess",
            creator => \&_htaccess_deny,
        },
    ) {

        my $sub = $file->{creator};
        my $content = &$sub($app_name);
        if ($content) {
            if (open my $fh, '>', $file->{name}) {
                print $fh $content;
                close $fh;
                print "  $file->{name}\n";
            } else {
                warn "Couldn't open $file->{name} to write: $!\n";
            }
        } else {
            warn "Couldn't get content of file $file->{name}\n";
        }
    }
}

sub _create_dhandler {
    my ($app_name) = @_;
    return << "EOF";
<\%init>
use ${app_name}::Dispatcher;
my \$dispatcher = ${app_name}::Dispatcher->new();
\$dispatcher->dispatch(\$m);
</\%init>
EOF

}

sub _create_autohandler {
    my ($app_name) = @_;
    return <<"EOF";
<html>
<head>
<title><% \$m->notes("title") || "$app_name" %></title>
</head>
<body>

<% \$content %>

</body>
</html>

<\%init>
# Before we generate our autohandler HTML, we locate the next component
# (in our case the MiniMVC dhandler) and call it, capturing its output.
# This means that notes() can be set before the autohandler generates a
# title and other component-dependent output.
my \$next = \$m->fetch_next;
my \$content = \$m->scomp(\$next);
</\%init>
EOF

}

sub _create_index {
    my ($app_name) = @_;
    return <<"EOF";
<& view/default.mhtml &>
EOF

}

sub _create_dispatcher {
    my ($app_name) = @_;
    return <<"EOF";
package ${app_name}::Dispatcher;

use base MasonX::MiniMVC::Dispatcher;

sub new {
    my (\$class) = \@_;
    my \$self = \$class->SUPER::new({
        'sample' => '${app_name}::Controller::Sample',
    });
}

1;
EOF

}

sub _create_controller_sample {
    my ($app_name) = @_;
    return <<"EOF";
package ${app_name}::Controller::Sample;

use strict;
use warnings;

=head1 NAME

${app_name}::Controller::Sample -- Sample MiniMVC controller

=head1 DESCRIPTION

This controller handles the sample/ part of the website.

=head1 METHODS

=head2 default()

This is called when someone goes to http://example.com/sample/

=cut

sub default {
    my (\$self, \$m, \@args) = \@_;
    \$m->notes("title", "$app_name: Sample Controller");
    \$m->comp("view/sample/default.mhtml");
}

1;
EOF

}

sub _create_model_sample {
    my ($app_name) = @_;
    return <<"EOF";
package ${app_name}::Model::Sample;

use strict;
use warnings;

=head1 NAME

${app_name}::Model::Sample -- Sample MiniMVC model 

=head1 DESCRIPTION

This is a stub model class for your MiniMVC application.  You could use
DBIx::Class, Class::DBI, or some other method to represent your data
here in an OO way.

You would then use ${app_name}::Model::Whatever from within your
Controller classes to access data.

=cut

1;
EOF

}

sub _create_controller_sample_test {
    my ($app_name) = @_;
    return <<"EOF";
use strict;
use warnings;

use Test::More qw(no_plan);

use_ok('${app_name}::Controller::Sample');
can_ok('${app_name}::Controller::Sample', 'default');
EOF
}

sub _create_model_sample_test {
    my ($app_name) = @_;
    return <<"EOF";
use strict;
use warnings;

use Test::More qw(no_plan);

use_ok('${app_name}::Model::Sample');
EOF
}

sub _create_view_default {
    my ($app_name) = @_;
    return <<"EOF";
<h1>MiniMVC Installed</h1>

<p>
Installed application <code>$app_name</code>.
</p>
<p>
<a href="sample/">View sample controller-generated page</a>.
</p>
<p>
To change the content of your front page, edit
<code>view/default.mhtml</code>.
</p>
EOF
}

sub _create_view_sample_default {
    my ($app_name) = @_;
    return <<"EOF";
<h1>Sample View</h1>

This view is called by
<code>${app_name}::Controller::Sample::default()</code>.

If you wanted to pass data, you'd do it via Mason's &lt;\%args&gt;
section.

<\%args>
\$foo => undef;
\@bar => undef;
</\%args>
EOF
}

sub _htaccess {
    return <<"EOF";
SetHandler mason-handler

DirectoryIndex index.mhtml

<Files autohandler>
    Order deny,allow
    Deny from all
</Files>

<Files dhandler>
    Order deny,allow
    Deny from all
</Files>
EOF
}

sub _htaccess_deny {
    my ($app_name) = @_;
    return <<"EOF";
Order deny,allow
Deny from all
EOF
}

1;
