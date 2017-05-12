#!/usr/bin/perl
use 5.012000;
use warnings;
use autodie;

use Cwd qw(abs_path);
use DBIx::RunSQL;
use Email::Valid;
use File::Basename qw(dirname basename);
use File::Copy::Recursive;
use File::Find::Rule;
use File::Path qw(mkpath);
use File::Spec;
use File::ShareDir;
use Getopt::Long qw(GetOptions);
use Pod::Usage  qw(pod2usage);
use String::Random;

use Dwimmer::Tools qw(sha1_base64 save_page _get_db);

my %opt;
GetOptions(\%opt,
    'email=s',
    'password=s',
    'root=s',
    'dbonly',
    'silent',
    'share=s',

    'setup',
    'upgrade',

    'username=s',

    'resetpw',
    'listusers',
    'showuser',
    'verify=s',
);
usage() if not $opt{root};

if ($opt{setup}) {
    if (-e $opt{root} and not $opt{dbonly}) {
        die "Root directory ($opt{root}) already exists"
    }

    usage() if not $opt{email};
    die 'Invalid e-mail' if not Email::Valid->address($opt{email});
    usage() if not $opt{password};
    die 'Password needs to be at least 6 characters' if length $opt{password} < 6;
} else {
    if (not -e $opt{root}) {
        die "Root directory ($opt{root}) does NOT exist.";
    }
}


if ($opt{resetpw}) {
    if (not $opt{password}) {
        die "Need password to set it";
    }
    if (not $opt{username}) {
        die "Need username to reset password";
    }

    $ENV{DWIMMER_ROOT} = $opt{root};
    my $db = _get_db();
    my $sha1 = sha1_base64( $opt{password} );
    my $user = $db->resultset('User')->find( { name => $opt{username} } );
    die "User was not found" if not $user;
    $user->sha1($sha1);
    $user->update;

    exit;
}

if (defined $opt{verify}) {
    die if $opt{verify} ne '0' and $opt{verify} ne '1';
    if (not -e $opt{root}) {
        die "Root directory ($opt{root}) does NOT exist.";
    }
    if (not $opt{username}) {
        die "Need username to verify";
    }

    $ENV{DWIMMER_ROOT} = $opt{root};
    my $db = _get_db();
    my $user = $db->resultset('User')->find( { name => $opt{username} } );
    die "User was not found" if not $user;
    $user->verified( $opt{verify} );
    $user->update;

    exit;
}

if ($opt{listusers}) {
    $ENV{DWIMMER_ROOT} = $opt{root};
    my $db = _get_db();
    my @users = $db->resultset('User')->all();
    die "No user was found" if not @users;
    foreach my $u (@users) {
        printf("%4s  '%s'\n", $u->id, $u->name);
    }

    exit;
}

if ($opt{showuser}) {
    if (not $opt{username}) {
        die "Need username to ";
    }

    $ENV{DWIMMER_ROOT} = $opt{root};
    my $db = _get_db();
    my $user = $db->resultset('User')->find( { name => $opt{username} } );
    die "User was not found" if not $user;
    foreach my $key (qw(id name email fname lname country state validation_key verified register_ts)) {
        say "$key " . ($user->$key // '');
    }

    exit;
}


if (not $opt{upgrade} and not $opt{setup}) {
    usage();
}




# When we are in the development environment (have .git) set this to the root directory
# When we are in the installation environment (have Makefile.PL) set this to the share/ subdirectory
my $dist_dir;
if (-e File::Spec->catdir(dirname(dirname abs_path($0)) , '.git') ) {
    $dist_dir = dirname(dirname abs_path($0))
} elsif (-e File::Spec->catdir(dirname(dirname abs_path($0)) , 'Makefile.PL') ) {
    $dist_dir = File::Spec->catdir( dirname(dirname abs_path($0)), 'share' );
} else {
    $dist_dir = File::ShareDir::dist_dir('Dwimmer');
}
# die $dist_dir;

my $db_dir = File::Spec->catdir($opt{root}, 'db');
mkpath $db_dir if not -e $db_dir;

if (not $opt{dbonly}) {
    foreach my $dir (qw(views public bin environments)) {
        my $from = File::Spec->catdir( $dist_dir, $dir );
        my $to   = File::Spec->catdir( $opt{root}, $dir );
		print "dircopy $from $to\n";
		chmod 0644, File::Find::Rule->file()->in($to) if -d $to;
        File::Copy::Recursive::dircopy( $from, $to ) or die $!;
    }
	my $from = File::Spec->catdir( $dist_dir, 'config.yml');
    my $to   = File::Spec->catdir( $opt{root} );
	print "fcopy $from $to\n";
	chmod 0644, File::Find::Rule->file()->in($to) if -d $to;
    File::Copy::Recursive::fcopy( $from, $to ) or die $!;
}

# backup the database
if ($opt{upgrade}) {
    my $db_dir = File::Spec->catdir($opt{root}, 'db');
    my $dbfile = File::Spec->catfile( $db_dir, 'dwimmer.db' );
    my $time = time;
    if (-e $dbfile) {
        File::Copy::Recursive::fcopy($dbfile, "$dbfile.$time");
    }
}

my $dbfile = File::Spec->catfile( $db_dir, 'dwimmer.db' );
if (not $opt{upgrade}) {
    setup_db($dbfile);
}

my @upgrade_from;

foreach my $sql ( glob File::Spec->catfile($dist_dir, 'schema', '*.sql' ) ) {
	next if basename($sql) !~ m{^\d+\.sql$};
	push @upgrade_from, sub {
	    my $dbfile = shift;

	    DBIx::RunSQL->create(
	        dsn => "dbi:SQLite:dbname=$dbfile",
	        sql => $sql,
	        verbose => 0,
	    );
	};
}

upgrades($dbfile);

say 'You can now launch the application and visit the web site';

exit;
##################################################################

sub setup_db {
    my $dbfile = shift;

    die "Database file '$dbfile' already exists\n" if -e $dbfile;

    # 0
    my $sql = File::Spec->catfile($dist_dir, 'schema', 'dwimmer.sql');
    DBIx::RunSQL->create(
        dsn => "dbi:SQLite:dbname=$dbfile",
        sql => $sql,
        verbose => 0,
    );

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");
    my $time = time;
    my $validation_key = String::Random->new->randregex('[a-zA-Z0-9]{10}') . $time . String::Random->new->randregex('[a-zA-Z0-9]{10}');
    $dbh->do('INSERT INTO user (name, sha1, email, validation_key, verified, register_ts) VALUES(?, ?, ?, ?, ?, ?)',
        {},
        'admin', sha1_base64($opt{password}), $opt{email}, $validation_key, 1, $time);

    $Dwimmer::Tools::dbfile = $dbfile;

    my $site = 1;
    $dbh->do("INSERT INTO site (name, owner) VALUES ('www', 1)");
    save_page($site, {
            create       => 1,
            editor_title => 'Welcome to your Dwimmer installation',
            editor_body  => '<h1>Dwimmer</h1>',
            author       => 1,
            filename     => '/',
    });


    return if $opt{silent};

    say 'Database created.';

    return;
}

sub upgrades {
    my $dbfile = shift;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile");

    my ($version) = $dbh->selectrow_array('PRAGMA user_version');
    foreach my $v ($version .. @upgrade_from-1) {
        $upgrade_from[$v]->($dbfile);
    }
}



sub usage {
    pod2usage();
}

=head1 SYNOPSIS

=head2 Required parameter:

   --root    PATH/TO/ROOT    path to the root of the installation

=head2 To setup a new instance:

   --setup
   --email email        of administrator
   --password PASSWORD  of administrator

Optional parameters:

   --dbonly             Create only the database (for development)
   --silent             no success report (for testing)

=head2 To upgrade run:

   --upgrade


=head2 Admin tools:

=over 4

=item * List users:

   --listusers

=item * Show details of a user:

   --showuser
   --username USERNAME    
   
=item * Set or remove verified bit of a user:

   --verify [0|1]
   --username USERNAME

=item * Set the password of a specific user:

   --resetpw
   --username USERNAME
   --password PASSWORD

=back

=cut

