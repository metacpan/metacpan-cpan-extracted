#!/usr/bin/env perl
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 3 of the License, or
#   (at your option) any later version.
#

package AI::SemanticNetwork;

unshift @INC, ( '.', 'lib', 'DBI', 'site/lib' );

BEGIN { $ENV{DBI_PUREPERL} = 1 }

my @files = qw{
  ./DBI.pm
  ./DBI/PurePerl.pm
};
mkdir './DBI';
use LWP::Simple;

foreach my $file (@files) {
    if ( -f $file ) {
        print "NOT downloading ", $file, "\n";
        next;
    }

    print "downloading ", $file, "\n";
    $content = get(
        "http://resources.freehal.org/resources/download/" . $file . ".txt" );
    if ($content) {

        # print $content;
        open my $file, '>', $file;
        print {$file} $content;
        close $file;
    }
}

use strict;
use warnings;
use Carp;

use Digest::MD5 qw(md5_hex);

BEGIN {
    use Exporter ();
    our ( $VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS );

    # set the version for version checking
    $VERSION = 0.01;

    @ISA = qw(Exporter);

    # functions
    @EXPORT = qw(&strip_to_base_word
      &semantic_network_key_exists
      &semantic_network_get_by_key
      &semantic_network_get_smalltalk
      &semantic_network_put
      &semantic_network_clean_cache
      &semantic_network_load
      &semantic_network_load_nosql
      &semantic_network_clean
      &semantic_network_connect
      &semantic_network_commit
      &semantic_network_execute_sql
      &semantic_network_get_sql_database_type );
    %EXPORT_TAGS = ();    # eg: TAG => [ qw!name1 name2! ],

    # your exported package globals go here,
    # as well as any optionally exported functions
    @EXPORT_OK = qw($Var1 %Hashit &func3);
}
our @EXPORT_OK;

# exported package globals go here
our $initialized;

# non-exported package globals go here
our $semantic_net__facts;
our $semantic_net__facts_with_variables;
our $semantic_net__smalltalk;
our $verbose;
our %strip_to_base_word_hash;
our $_number_of_facts;
our %semnet_keys_hash;
our @hooks_for_add;
our @hooks_for_init;
our @hooks_for_template_processing;
our @hooks_for_percent;
our @hooks_for_more_prot_data;
our @endings_to_remove;
our %cache__indices_for_facts;
our $dbh;
our $sql;
our $sql_for_records;
our %config;
our $getlang;
our $table_for_facts_normal;
our $optional_hook_args;
our $directory;

# initialize package globals, first exported ones
$initialized = 0;

# then the others
semantic_network_clean();
@hooks_for_add                 = ();
@hooks_for_init                = ();
@hooks_for_template_processing = ();
@hooks_for_percent             = ();
@hooks_for_more_prot_data      = ();
$sql                           = q{};
%config                        = ();

our $VERB                       = 0;
our $SUBJECT                    = 1;
our $OBJECT                     = 2;
our $ADVERBS                    = 3;
our $SUBCLAUSES_OR_QUESTIONWORD = 4;
our $PRIO                       = 5;

%strip_to_base_word_hash = ();
$_number_of_facts        = 0;
$verbose                 = 1;

%semnet_keys_hash = ();

# keys %semnet_keys_hash = 10000;

@endings_to_remove = (
    'en',
    sort { length $a <=> length $b }
      qw(e es er ere en st n in innen erin erinnen)
);

%cache__indices_for_facts = ();

$sql_for_records = [];
$directory       = '.';

# destructor
END {
    undef $semantic_net__facts;
    undef $semantic_net__facts_with_variables;
}

# use
#use Devel::DumpSizes qw/dump_sizes/;

# code

sub semantic_network_clean_cache {
    undef %cache__indices_for_facts;
    %cache__indices_for_facts = ();
}

sub semantic_network_clean {
    undef $semantic_net__facts;
    undef $semantic_net__facts_with_variables;
    undef $semantic_net__smalltalk;
    $semantic_net__facts                = [];
    $semantic_net__facts_with_variables = [];
    $semantic_net__smalltalk            = [];
    semantic_network_clean_cache();

#	use DBM::Deep;
#	eval 'tie @$semantic_net__facts, \'DBM::Deep\', \'cache__semantic_net__facts.tmp\';';
#	print $@;

}

sub file_modified {
    my ($file) = @_;

    use File::stat;
    use Time::localtime;

    # my $hash_string = ctime(stat($file)->mtime);
    open my $file_handle, '<', $file;
    binmode($file_handle);
    my $hash_string = md5_hex( ( join( '', <$file_handle> ) ) );
    close $file_handle;
    print $file,        "\n";
    print $hash_string, "\n";

    # look for date
    $sql .=
qq{ SELECT * FROM files WHERE `file` LIKE "$file" AND `md5` LIKE "$hash_string"};
    my $sth = $dbh->prepare($sql);
    print $sql, "\n";
    $sth and $sth->execute();

    # this is the return value
    my $file_was_modified = !$sth->fetchrow_arrayref;

    print '$file_was_modified: ', $file_was_modified || 0, "\n";
    if ($file_was_modified) {

        # look is file is in database
        $sql = qq{SELECT `md5` FROM files WHERE `file` LIKE "$file"};
        print $sql, "\n";
        $sth = $dbh->prepare($sql);
        $sth and $sth->execute();

        if ( !$sth->fetchrow_arrayref ) {
            $sql =
qq{INSERT INTO files (file, md5) VALUES ("$file", "$hash_string")};
            print $sql, "\n";
            $sth = $dbh->prepare($sql);
            $sth and $sth->execute();

            $file_was_modified = 1;
        }
        else {
            $sql =
              qq{UPDATE files SET md5 = "$hash_string" WHERE `file` = "$file"};
            $sth = $dbh->prepare($sql);
            $sth and $sth->execute();
        }
    }

    $sql = q{};

    return $file_was_modified;
}

sub semantic_network_get_sql_database_type {
    if ( $config{'mysql'} && $config{'mysql'}{'database'} ) {
        return 'mysql';
    }
    return 'sqlite';
}

eval 'use DBI;';
warn $@ if $@;

sub semantic_network_connect {
    eval 'use DBI;';
    warn $@ if $@;

    # parameters
    my %arg = ( config => {}, dir => '.' );
    %arg = ( %arg, @_ );

    %config = %{ $arg{config} } if %{ $arg{config} };

    if ( $arg{dir} && length $arg{dir} > 1 ) {
        $directory = $arg{dir};
    }

    #if ( $dbh ) {
    #$dbh->disconnect();
    #}

    # use mysql?
    if ( $config{'mysql'} && $config{'mysql'}{'database'} ) {
        eval q{
        my $db_string = "DBI:mysql:database=" . $config{'mysql'}{'database'};
        if ( !$config{'mysql'}{'host'} ) {
            $config{'mysql'}{'host'} = 'freehal.selfip.net';
        }
        $db_string .= ';host=' . $config{'mysql'}{'host'};
        print $db_string, "\n";
        
		my $user      = $config{'mysql'}{'user'};
		my $password  = $config{'mysql'}{'password'};
		$dbh          = DBI->connect( $db_string, $user, $password )
			or warn(
			"not connected to ",
			$config{'mysql'}{'database'},
			", user ",
			$config{'mysql'}{'user'},
			
			": "
			);
        } if !$::batch;
        warn $@ if $@;
    }

    elsif ($::batch) {
        #my $db_string = "DBI:CSV:f_dir=.";
        #$dbh = DBI->connect($db_string)
        #  or warn( "not connected to sqlite: ", $! );

    }

    # if not, use sqlite!
    else {
        return if $dbh;
        my $db_string = "DBI:SQLite:dbname=" . $arg{dir} . "/database.tmp";
        $dbh = DBI->connect( $db_string, q{}, q{} )
          or warn( "not connected to sqlite: ", $! );
    }

    if ($getlang) {
        $table_for_facts_normal = 'facts_normal_' . &$getlang();
    }
    else {
        $table_for_facts_normal = 'facts_normal';
    }
}

sub semantic_network_load {

    # parameters
    my %arg = (
        files              => [],
        optional_hook_args => [],
        config             => {},
        execute_hooks      => 1,
    );
    %arg = ( %arg, @_ );

    # initialize hash
    %semnet_keys_hash = ( 1 => 1 );

    # better names
    $optional_hook_args = $arg{optional_hook_args};
    my $execute_hooks = $arg{execute_hooks};
    %config = %{ $arg{config} } if %{ $arg{config} };
    my $CLIENT = ${ $arg{client} || \'' };

    # init sql
    unshift @INC, ( '.', 'lib', 'DBI', 'site/lib' );
    eval 'use DBI;';
    warn $@ if $@;

    # init client messages
    my $display_text = '';

    foreach my $hook (@hooks_for_more_prot_data) {
        &$hook(@$optional_hook_args);
    }

    if ($CLIENT) {
        $display_text .= 'Lade semantisches Netz. Bitte warten...<br>';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }

    # create table
    $sql = qq{create table $table_for_facts_normal (`pk` }
      . (
        $config{'mysql'}{'database'}
        ? 'INT NOT NULL AUTO_INCREMENT PRIMARY KEY'
        : 'INTEGER PRIMARY KEY AUTOINCREMENT'
      )
      . qq{,
                                          `from_file` varchar(250),
                                          `key` varchar(50),
            							  `verb` varchar(50),
                                          `subj` varchar(50),
                                          `obj` varchar(50),
                                          `advs` varchar(50),
                                          `prio` varchar(50),
                                          `verb__1` varchar(50),
                                          `subj__1` varchar(50),
                                          `obj__1` varchar(50),
                                          `advs__1` varchar(50),
                                          `quesword__1` varchar(50),
                                          `verb__2` varchar(50),
                                          `subj__2` varchar(50),
                                          `obj__2` varchar(50),
                                          `advs__2` varchar(50),
                                          `quesword__2` varchar(50),
                                          `verb__3` varchar(50),
                                          `subj__3` varchar(50),
                                          `obj__3` varchar(50),
                                          `advs__3` varchar(50),
                                          `quesword__3` varchar(50),
                                          `verb__4` varchar(50),
                                          `subj__4` varchar(50),
                                          `obj__4` varchar(50),
                                          `advs__4` varchar(50),
                                          `quesword__4` varchar(50),
                                          `verb__5` varchar(50),
                                          `subj__5` varchar(50),
                                          `obj__5` varchar(50),
                                          `advs__5` varchar(50),
                                          `quesword__5` varchar(50),
                                          `verb__6` varchar(50),
                                          `subj__6` varchar(50),
                                          `obj__6` varchar(50),
                                          `advs__6` varchar(50),
                                          `quesword__6` varchar(50),
                                          
                                          UNIQUE(`key`,
            							  `verb`,
                                          `subj`,
                                          `obj`,
                                          `advs`,
                                          `prio`,
                                          `verb__1`,
                                          `subj__1`,
                                          `obj__1`,
                                          `verb__2`,
                                          `subj__2`,
                                          `obj__2`,
                                          `verb__3`,
                                          `subj__3`,
                                          `obj__3`,
                                          `verb__4`,
                                          `subj__4`,
                                          `obj__4`,
                                          `verb__5`,
                                          `subj__5`,
                                          `obj__5`,
                                          `verb__6`,
                                          `subj__6`,
                                          `obj__6`)
                                          )};

    eval {
        local $SIG{'__DIE__'};
        my $sth = $dbh->prepare($sql)
          or warn 'preparing: ',
          $dbh->errstr,
          "\n",
          $sql;
        $sth and $sth->execute()
          or warn 'error executing: ',
          $dbh->errstr,
          "\n",
          $sql;
    };

    $sql = qq{create table files (`file` varchar(250) UNIQUE,
                                   `md5` varchar(250)
                                          )};

    eval {
        local $SIG{'__DIE__'};
        my $sth = $dbh->prepare($sql);
        $sth and $sth->execute()
          or warn 'error executing: ',
          $dbh->errstr,
          "\n",
          $sql;
    };
    $sql = q{};

    open my $TEMP_FILE, '>', 'sql.tmp';
    close $TEMP_FILE;

    # load from files
    my @facts_with_limit = ();
  FILE:
    foreach my $file ( @{ $arg{files} } ) {

        if ( $file =~ /prot$/ ) {
            if ($CLIENT) {
                $display_text .=
                    'Erstelle aus der Textdatei ' 
                  . $file
                  . ' eine Datenbankdatei...<br>';
                print $CLIENT 'DISPLAY:', $display_text, "\n";
            }
            ( my $pro_file = $file ) =~ s/.$//m;
            foreach my $hook (@hooks_for_template_processing) {
                &$hook( $file, $pro_file, @$optional_hook_args )
                  if !-f $pro_file;
            }
            next;
        }

        if ( !file_modified($file) ) {
            if ($CLIENT) {
                $display_text .=
                  'Datenbankdatei nicht veraendert ' . $file . '...<br>';
                print $CLIENT 'DISPLAY:', $display_text, "\n";
            }
            print 'Skipping: ', $file, "\n";
            print 'reason: not modified', "\n";

            # disabled because it is not useful
            if ($execute_hooks) {
                my @facts = ();

                my $tolerate = 0;

                foreach my $hook (@hooks_for_add) {
                    $tolerate =
                      &$hook( 0, [], @$optional_hook_args, $file, $tolerate );
                }

                if ($tolerate) {

                    $sql .= qq{
						SELECT DISTINCT verb, subj, obj, advs, prio,
							   verb__1, subj__1, obj__1,
							   advs__1, quesword__1, verb__2,
							   subj__2, obj__2, advs__2, quesword__2,
							   verb__3, subj__3, obj__3, advs__3,
							   quesword__3, verb__4, subj__4, obj__4,
							   advs__4, quesword__4, verb__5, subj__5,
							   obj__5, advs__5, quesword__5, verb__6,
							   subj__6, obj__6, advs__6, quesword__6
						FROM $table_for_facts_normal
						WHERE `from_file` = "$file"
					};

                    my $sth = $dbh->prepare($sql);
                    $sth->execute()
                      or warn 'error executing: ', $dbh->errstr, "\n", $sql
                      if ($sth);

                    $sql = q{};

                    # form to right format
                    my $data_ref;

                    my $i = 500;

                  RECORD:
                    while (
                        $tolerate
                        && (
                            $data_ref = [
                                $sth->fetchrow_arrayref,
                                $sth->fetchrow_arrayref,
                                $sth->fetchrow_arrayref,
                                $sth->fetchrow_arrayref,
                                $sth->fetchrow_arrayref,
                            ]
                        )
                      )
                    {
                        foreach my $data_ref_sub (@$data_ref) {
                            push @facts,
                              format_convert_sql_to_array($data_ref_sub)
                              if $data_ref_sub && $data_ref_sub->[0];
                        }
                        last if !$data_ref->[-1];
                        $i -= 5;

                        if ( $i == 0 ) {
                            foreach my $hook (@hooks_for_add) {
                                $tolerate =
                                  &$hook( 0, \@facts, @$optional_hook_args,
                                    $file, $tolerate );
                                if ( !$tolerate ) {
                                    last RECORD;
                                }
                            }
                            undef @facts;
                            @facts = ();

                            $i = 500;
                            semantic_network_commit();
                        }
                    }
                    if ( scalar @facts ) {
                        foreach my $hook (@hooks_for_add) {
                            &$hook( 0, \@facts, @$optional_hook_args, $file,
                                $tolerate );
                        }
                        undef @facts;
                        @facts = ();
                    }

                    undef @facts;
                }
            }

            if ( $_number_of_facts > 5_000 ) {
                if ($CLIENT) {
                    $display_text .= 'Zwischenspeichern... Bitte warten...<br>';
                    print $CLIENT 'DISPLAY:', $display_text, "\n";
                }
                semantic_network_commit();
            }

            next FILE;
        }

        if ($CLIENT) {
            $display_text .= 'Lade Datenbankdatei ' . $file . '...<br>';
            print $CLIENT 'DISPLAY:', $display_text, "\n";
        }

        open my $h, '<', $file or carp 'Error while opening: ', $file;
        print "\nLoading $file\n";
        while ( defined( my $fact = <$h> ) ) {
            next if $fact =~ /^\s*?[#]/;
            next if !$fact;

            # copy
            my $orig_fact = $fact;

            # new fact data structure
            my $array_fact;

            # parse
            {
                $fact = lc $fact;
                chomp $fact;
                $fact =~ s/\s+[<][>]\s+[<][>]\s+/ <> nothing <> /gm;
                $fact =~ s/[<][>]/ <> /gm;
                $fact =~ s/\s+/ /gm;
                $fact =~ s/["]/'/gm;

                my $ok =
                  ( $fact =~
m/^([^><]*?)\s+?[<][>]\s+?([^><]*?)\s+?[<][>]\s+?([^><]*?)\s+?[<][>]\s+?([^><]*?)\s+?[<][>]\s+?(.+?)\s+?([^><]*?)$/
                  );

                if ( !$ok ) {
                    print "\rinvalid: ", $fact, "\n";
                }

                #$fact = [ split /[<][>]/, $fact ];
                #foreach my $item (@$fact) {
                #$item =~ s/^\s//igm;
                #$item =~ s/\s$//igm;
                #}

                #my ( $verb, $subj, $obj, $advs ) = (
                #shift @$fact,
                #shift @$fact,
                #shift @$fact,
                #shift @$fact
                #);
                #my $prio = pop @$fact;

                #$fact = join '<>', @$fact;
                #$fact = [ split /\s*[;][;]\s*/, $fact ];

                ( my $verb, my $subj, my $obj, my $advs, $fact, my $prio ) =
                  ( $1, $2, $3, $4, $5, $6 || 50 );

                chomp $prio;

                next if !$verb;

                $fact = [ split( /\s*[;][;]\s*/, $fact ) ];

                foreach my $clause (@$fact) {
                    $clause = [ split /[<][>]/, $clause ];
                    foreach my $item (@$clause) {
                        $item =~ s/nothing//igm;
                        $item =~ s/(^\s+)|(\s+$)//igm;
                        chomp $item;
                    }
                }
                @$fact = grep { join '', @$_ } @$fact;

                $prio =~ tr/<//d;
                $prio =~ tr/>//d;

                # replace strings for compatibility
                # with older database versions

                if ( $subj =~ /^no\s/ ) {
                    $subj =~ s/^no\s/a /igm;
                    $advs .= ';' if $advs;
                    $advs .= 'not';
                }
                if ( $obj =~ /^no\s/ ) {
                    $obj =~ s/^no\s/a /igm;
                    $advs .= ';' if $advs;
                    $advs .= 'not';
                }
                if ( $subj =~ /^kein.?.?\s/ ) {
                    $subj =~ s/^kein(.?.?)\s/ein$1 /igm;
                    $advs .= ';' if $advs;
                    $advs .= 'nicht';
                }
                if ( $obj =~ /^kein.?.?\s/ ) {
                    $obj =~ s/^kein(.?.?)\s/ein$1 /igm;
                    $advs .= ';' if $advs;
                    $advs .= 'nicht';
                }
                if ( $obj =~ /(^|\s)nicht\s/ ) {
                    $obj =~ s/(^|\s)nicht\s/ /igm;
                    $advs .= ';' if $advs;
                    $advs .= 'nicht';
                }

                if (   $subj !~ /..[_\s]../
                    && $obj !~ /..[_\s]../
                    && $verb eq '=' )
                {
                    $verb = 'sein';
                }

                # make data structure
                $array_fact = [ $verb, $subj, $obj, $advs, $fact, $prio ];

                if ($array_fact) {
                    semantic_network_put(
                        fact               => $array_fact,
                        optional_hook_args => $optional_hook_args,
                        sql_execute        => 0,
                        from_file          => $file
                    );
                    push @facts_with_limit, $array_fact;
                }
            }

            #if ( scalar @facts_with_limit > 5000 ) {
            ## select undef, undef, undef, 1;
            #if ( $execute_hooks ) {
            #foreach my $hook (@hooks_for_add) {
            #&$hook(0,
            #\@facts_with_limit,
            #@$optional_hook_args);
            ##threads->create($hook,
            ##	   2,
            ##	   \@facts_with_limit,
            ##	   @$optional_hook_args);
            #}
            #}
            #undef @facts_with_limit;
            #@facts_with_limit = ();
            #}
        }

        if ( $_number_of_facts > 5_000 ) {
            if ($CLIENT) {
                $display_text .= 'Zwischenspeichern... Bitte warten...<br>';
                print $CLIENT 'DISPLAY:', $display_text, "\n";
            }
            semantic_network_commit();
        }

        if ( scalar @facts_with_limit ) {
            if ($execute_hooks) {
                my $tolerate = 0;
                foreach my $hook (@hooks_for_add) {
                    $tolerate =
                      &$hook( 0, \@facts_with_limit, @$optional_hook_args,
                        $file, $tolerate, );

                    #threads->create($hook,
                    #	   2,
                    #	   \@facts_with_limit,
                    #	   @$optional_hook_args);
                }
            }
            undef @facts_with_limit;
            @facts_with_limit = ();
        }

        if ($sql) {
            my $sth = $dbh->prepare($sql);
            $sth->execute()
              or warn 'error executing: ', $dbh->errstr, "\n", $sql
              if ($sth);
            $sql = q{};
        }
    }

    undef %semnet_keys_hash;
    if ($CLIENT) {
        $display_text .= 'Zwischenspeichern... Bitte warten...<br>';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }
    semantic_network_commit();

    foreach my $hook (@hooks_for_init) {
        &$hook( 0, [], @$optional_hook_args, '', 0 );
    }

    print "\n";

    if ($optional_hook_args) {
        foreach my $hook (@hooks_for_percent) {

            &$hook( @$optional_hook_args, 100 );
        }

        select undef, undef, undef, 0.5;

        foreach my $hook (@hooks_for_percent) {

            &$hook( @$optional_hook_args, 0 );
        }
    }

    open my $TEMP_FILE, '>', 'sql.tmp';
    close $TEMP_FILE;

    if ($CLIENT) {
        $display_text .=
'<br>Das semantische Netz wurde geladen. Das Programm ist betreibsbereit.';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }

    $initialized = 1;
}

sub semantic_network_load_nosql {

    # parameters
    my %arg = (
        files              => [],
        optional_hook_args => [],
        config             => {},
        execute_hooks      => 1,
        extra_hooks_for_more_prot_data => [],
    );
    %arg = ( %arg, @_ );

    # initialize hash
    %semnet_keys_hash = ( 1 => 1 );

    # better names
    $optional_hook_args = $arg{optional_hook_args};
    my $execute_hooks = $arg{execute_hooks};
    %config = %{ $arg{config} } if %{ $arg{config} };
    my $CLIENT = ${ $arg{client} || \'' };

    # init sql
    unshift @INC, ( '.', 'lib', 'DBI', 'site/lib' );
    eval 'use DBI;';

    # init client messages
    my $display_text = '';

    foreach my $hook (@hooks_for_more_prot_data, @{$arg{extra_hooks_for_more_prot_data}||[]}) {
        &$hook(@$optional_hook_args);
    }

    if ($CLIENT) {
        $display_text .= 'Lade semantisches Netz. Bitte warten...<br>';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }

    my $sql;

    open my $TEMP_FILE, '>', 'sql.tmp';
    close $TEMP_FILE;

    # load from files
    my @facts_with_limit = ();
  FILE:
    foreach my $file ( @{ $arg{files} } ) {

        if ( $file =~ /prot$/ ) {
            if ($CLIENT) {
                $display_text .=
                    'Erstelle aus der Textdatei ' 
                  . $file
                  . ' eine Datenbankdatei...<br>';
                print $CLIENT 'DISPLAY:', $display_text, "\n";
            }
            ( my $pro_file = $file ) =~ s/.$//m;
            foreach my $hook (@hooks_for_template_processing) {
                &$hook( $file, $pro_file, @$optional_hook_args )
                  if !-f $pro_file;
            }
            next;
        }

    }

    undef %semnet_keys_hash;
    if ($CLIENT) {
        $display_text .=
'<br>Das semantische Netz wurde geladen. Das Programm ist betreibsbereit.';
        print $CLIENT 'DISPLAY:', $display_text, "\n";
    }

    $initialized = 1;
}

sub semantic_network_execute_sql {
    my ($sql) = @_;
    my $sth = $dbh->prepare($sql)
      or warn 'cannot prepare: ',
      $dbh->errstr,
      "\n",
      '-------',
      $sql;
    $sth->execute()
      or warn 'error executing: ', $dbh->errstr, "\n", '-------', $sql
      if ($sth);
    return $sth;
}

sub semantic_network_commit {
    print "\r\nCommit...                  \n";

#    my $sth = $dbh->prepare("COMMIT");
#    $sth->execute()
#      if ($sth);
#    my $sth = $dbh->prepare("BEGIN");
#    $sth->execute()
#      if ($sth);

    #foreach my $sql_data (@$sql_for_records) {

    #my $sth = $dbh->prepare($sql_data)
    #or warn 'cannot prepare: ',
    #$dbh->errstr,
    #"\n",
    #'-------',
    #$sql_data
    #;;
    #$sth->execute() or warn 'error executing: ',
    #$dbh->errstr,
    #"\n",
    #'-------',
    #$sql_data
    #if ( $sth )
    #;
    #}

    open my $TEMP_FILE, '<', 'sql.tmp';

    my $sql_insert = qq{ INSERT };

    if ( $config{'mysql'} && $config{'mysql'}{'database'} ) {
        $sql_insert .= qq{ IGNORE };
    }
    else {
        $sql_insert .= qq{ OR IGNORE };
    }
    $sql_insert .= qq{ INTO $table_for_facts_normal
		 ( `key`, `from_file`, `verb`, `subj`, `obj`, `advs`, `prio` };

    foreach my $i ( 1 .. 6 ) {
        $sql_insert .=
          qq{ , `verb__$i`, `subj__$i`, `obj__$i`, `advs__$i`, `quesword__$i` };
    }

    $sql_insert .= qq{ ) };
    if ( $config{'mysql'} && $config{'mysql'}{'database'} ) {
        $sql_insert .= qq{ VALUES ( };
    }
    else {
        $sql_insert .= qq{ SELECT };
    }
    $sql_insert .= qq{ ?, ?, ?, ?, ?, ?, ? };
    foreach my $i ( 1 .. 6 ) {
        $sql_insert .= qq{ , ?, ?, ?, ?, ? };
    }
    if ( $config{'mysql'} && $config{'mysql'}{'database'} ) {
        $sql_insert .= qq{ ) };
    }

    # else { <-- correct
    elsif (0) {    # <-- NOT correct
        $sql_insert .= qq{
			WHERE NOT EXISTS (
				SELECT 1 FROM $table_for_facts_normal
				WHERE +`key` = ? AND 10 != ? AND `verb` = ? AND `subj` = ? AND `obj` = ? AND `advs` = ? AND `prio` = ?
		};
        foreach my $i ( 1 .. 6 ) {
            $sql_insert .=
qq{ AND `verb__$i` = ? AND `subj__$i` = ? AND `obj__$i` = ? AND `advs__$i` = ? AND `quesword__$i` = ? };
        }
        $sql_insert .= qq{
			)
		};
    }

    ####print $sql_insert;

    my $sth = $dbh->prepare($sql_insert);

    # while (defined( my $sql_data = <$TEMP_FILE>)) {
    foreach my $sql_data (<$TEMP_FILE>) {

        my @sql_data = split /[,][,][,]/, $sql_data;

        $sth->execute(
            @sql_data,
            (
                     $config{'mysql'}
                  && $config{'mysql'}{'database'}
                  ## ? () : @sql_data) <-- correct line
                ? ()
                : ()
            )
          )
          or $dbh->errstr !~ /unique/i && warn 'error executing: ',
          $dbh->errstr, "\n", '-------', $sql_data
          if ($sth);
    }

    close $TEMP_FILE;

    open my $TEMP_FILE, '>', 'sql.tmp';
    close $TEMP_FILE;

#    my $sth = $dbh->prepare("COMMIT");
#    $sth->execute()
#      if ($sth);
}

use Data::Dumper;

sub semantic_network_put {

    # parameters
    my %arg = ( sql_execute => 0 );
    %arg = ( %arg, @_ );

    # is it not set?
    if ( !$arg{fact} ) {
        return;
    }

    # better names
    my $fact               = $arg{fact};
    my $exec_hooks         = $arg{execute_hooks};
    my $optional_hook_args = $arg{optional_hook_args} || $optional_hook_args;
    my $sql_execute        = $arg{sql_execute};
    my $from_file          = $arg{from_file};

    # add the fact to semantic net with different keys:
    my $key;

    if ($sql_execute) {

        #print Dumper $fact;
        #select undef, undef, undef, 3;
    }

    $key = strip_to_base_word( lc $fact->[1] );

    # add to net
    semantic_network_add(
        key                => $key,
        fact               => $fact,
        optional_hook_args => $optional_hook_args,
        sql_execute        => $sql_execute,
        from_file          => $from_file
    );

    foreach my $key ( strip_to_base_word( lc $fact->[1], 1 ) ) {

        if ($sql_execute) {
            print "KEY: ", $key, "\n";
        }

        # add to net
        semantic_network_add(
            key                => $key,
            fact               => $fact,
            optional_hook_args => $optional_hook_args,
            sql_execute        => $sql_execute,
            from_file          => $from_file
        );
    }

    $key = strip_to_base_word( lc $fact->[2] );

    # add to net
    semantic_network_add(
        key                => $key,
        fact               => $fact,
        optional_hook_args => $optional_hook_args,
        sql_execute        => $sql_execute,
        from_file          => $from_file
    );

    foreach my $key ( strip_to_base_word( lc $fact->[2], 1 ) ) {

        # add to net
        semantic_network_add(
            key                => $key,
            fact               => $fact,
            optional_hook_args => $optional_hook_args,
            sql_execute        => $sql_execute,
            from_file          => $from_file
        );
    }

    # execute hooks?
    if ($exec_hooks) {
        foreach my $hook (@hooks_for_add) {

            &$hook(
                0,
                [$fact],
                @$optional_hook_args,
                $from_file,
                0,    # tolerate?
            );
        }
    }
}

sub semantic_network_add {

    # parameters
    my %arg = ( sql_execute => 0, from_file => '' );
    %arg = ( %arg, @_ );

    # is it not set?
    if ( !$arg{key} ) {
        return;
    }
    if ( !$arg{fact} ) {
        return;
    }
    if ( ref $arg{fact} ne 'ARRAY' ) {
        print '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', "\n";
        print "Bug detected: no ARRAY ref:\n";
        use Data::Dumper;
        print Dumper $arg{fact};
        print '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!', "\n";
        return;
    }

    # better names
    my $key                = $arg{key};
    my $fact               = $arg{fact};
    my $optional_hook_args = $arg{optional_hook_args};
    my $sql_execute        = $arg{sql_execute};
    my $from_file          = $arg{from_file} || 'facts';

    # correct keys
    #if ( $key =~ /^[a-h][-~]?$/ || $key =~ /anything/ ) {
    #print q{$key = '$$anything$$'!};
    #$key = '$$anything$$';
    #}

    #if ( $key eq '$$anything$$' ) {
    #		print Dumper $fact;
    #	}

    # smalltalk fact
    #if ( grep { $_->[0] =~ /[=][>]/ } @{ $fact->[4] } ) {
    #	if ( $semantic_net__smalltalk->[-1] ne $fact ) {
    #		push @$semantic_net__smalltalk, format_convert_array_to_hash ($fact);
    #	}
    #}

    # normal fact
    {

        # add fact to semantic network

        ## push @$semantic_net__facts,
        ##  	[ $key, $fact ];

        #my $is_limit_exceeded = @$sql_for_records > 500;

        #if ( scalar @$sql_for_records == 0 || $is_limit_exceeded ) {
        #	if ( scalar @$sql_for_records > 0 ) {
        #		push @$sql_for_records, qq{ ; };
        #	}
        #}
        #else {
        #	$sql_for_records->[-1] .= q{ union all };
        #}
        #$sql_for_records->[-1] .= q{ select };
        # $sql_for_records->[-1] .= q{ VALUES ( };

        push @$sql_for_records, q{};

        $fact->[5] =~ tr/ //d;
        $fact->[5] =~ s/\s//gm;
        chomp $fact->[5];
        $fact->[5] ||= 50;

        $sql_for_records->[-1] .=
qq{$key,,,$from_file,,,$fact->[0],,,$fact->[1],,,$fact->[2],,,$fact->[3],,,$fact->[5]};
        foreach my $i ( 0 .. 5 ) {
            my $sub_fact = $fact->[4]->[$i];
            if ( !$sub_fact ) {
                $sql_for_records->[-1] .= qq{,,,,,,,,,,,,,,,};
                next;
            }

            if ( !$sub_fact->[0] || $sub_fact->[0] =~ /nothing/ ) {
                $sub_fact->[0] = $sub_fact->[1];
            }

            $sql_for_records->[-1] .=
qq{,,,$sub_fact->[0],,,$sub_fact->[1],,,$sub_fact->[2],,,$sub_fact->[3],,,$sub_fact->[4]};
        }

        open my $TEMP_FILE, '>>', 'sql.tmp';
        $sql_for_records->[-1] =~ s/[\r\n]//gm;
        print $TEMP_FILE $sql_for_records->[-1], "\n";
        close $TEMP_FILE;
        @$sql_for_records = ();

        #$sql_execute = 0;
        if (
            $sql_execute
            || scalar @$sql_for_records > 100_000

          #|| ( $config{'mysql'}{'database'} && scalar @$sql_for_records > 500 )
          )
        {

            #  || $config{'mysql'}{'database'}
            semantic_network_commit();
            $sql_for_records = [];
        }
        $_number_of_facts += 1;

        if ($verbose) {
            if ( $_number_of_facts % 300 == 0 ) {
                print "\rfact no " . $_number_of_facts
                  if $_number_of_facts % 10 == 0;

                if ($optional_hook_args) {
                    foreach my $hook (@hooks_for_percent) {

                        &$hook( @$optional_hook_args,
                            100 / 450_000 * $_number_of_facts );
                    }
                }
            }
        }
        $semnet_keys_hash{$fact} = 1;
    }

}

sub strip_to_base_word {
    my ( $word, $as_list ) = @_;

    if ( !defined $word ) {
        return '-';
    }

    return 'nothing' if $word =~ /^nothing/;

    if ( length( $word || '' ) < 2
        || ( length( $word || '' ) < 3 && $word =~ /s$/ ) )
    {

        #    	if ( $word !~ /[\-~]$/ ) {
        #        	$word = ($word||'') . '-';
        #		}
        return $word;
    }

    #$word =~ s/^(.ein.?.?)\s/$1qq/igm;

    my $word_beginning = $word;

    $word =~
s/^(der|die|das|den|des|dem|den|kein|ein|eine|einer|einem|einen|eines|a|an|the)\s//igm;
    $word =~ s/^([mds]ein)[a-z]?[a-z]?(\s|$)/$1$2/igm;

    $word =~ s/_/ /igm;

    #$word =~ s/^(.ein.?.?)\s/$1qq/igm;
    if ( $word =~ /\s/ && !$as_list ) {

        $word = join ' ',
          grep { $_ ne '-' }
          map { strip_to_base_word($_) } grep { $_ } split /\s+/, $word;

        return $word;
    }
    if ( $word =~ /\s/ && $as_list ) {
        return map { strip_to_base_word($_) } split /\s+/, $word;
    }

    if ( $strip_to_base_word_hash{$word} ) {
        return $strip_to_base_word_hash{$word};
    }
    $word =~ s/\s+$//gm;
    return $word if $word =~ /[\-~]$/;

    $word ||= q{};

    my $changed = 0;

  ENDING:
    foreach my $ending (@endings_to_remove) {
        if ( $word =~ /$ending$/ ) {

            $word =~ s/$ending$//m;
            $changed = 1 if length($ending) > 2;
            last ENDING;
        }
    }

    if ($changed) {
        $word .= '-';
    }
    else {
        $word .= '-';
    }

    if ( $word =~ /^[a-h][-~]?$/ ) {
        $word = '$$anything$$';
    }

    $strip_to_base_word_hash{$word_beginning} = $word;

    return $word;
}

sub semantic_network_get_smalltalk {
    my $sql .= qq{SELECT };
    $sql .= qq{  *
    	FROM $table_for_facts_normal
        
        WHERE verb__1 LIKE "f=>%"
        OR verb__1 LIKE "q=>%"
	};

    my $sth;
    eval {
        local $SIG{'__DIE__'};
        $sth = $dbh->prepare($sql);
    };
    if ( !$sth ) {
        print 'no smalltalk facts found.';
        $sql = q{};
        return ( [] );
    }
    $sth->execute()
      or warn 'error executing: ', $dbh->errstr, "\n", $sql
      if ($sth);
    print "$dbh->errstr\n" if $dbh->errstr;

    my @records = ();

    # form to right format
    my $data_ref;
    my $count_of_records = 0;
    while ( $data_ref = $sth->fetchrow_arrayref ) {
        $count_of_records += 1;
        my @data = @$data_ref;
        shift @data;
        shift @data;
        shift @data;
        push @records,
          format_convert_array_to_hash( format_convert_sql_to_array( \@data ) );
    }

    return ( \@records );
}

sub semantic_network_get_count_of_facts {
    $sql .= qq{
		SELECT *
    	FROM $table_for_facts_normal
    };

    my $sth = $dbh->prepare($sql);
    $sth->execute()
      or warn 'error executing: ', $dbh->errstr, "\n", $sql
      if ($sth);

    $sql = q{};

    return $sth->rows;
}

my %cache_semantic_network_get_by_key = ();

sub semantic_network_get_by_key {

    # parameters
    my %arg = ( as => 'hash', helper => 0 );
    %arg = ( %arg, @_ );

    # return if invalid argument
    return ( [] ) if $arg{key} =~ /nothing/;

    # better names
    my $as              = $arg{as};
    my @keys            = ();
    my $return_anything = grep { $_ eq '...' } @{ $arg{'keys'} || [] };
    push @keys, strip_to_base_word( $arg{key} );
    @keys = () if !$arg{key};
    push @keys, grep { $_ !~ /^([-~])$/ }
      map { strip_to_base_word($_) }
      grep { $_ && $_ !~ /nothing/ } @{ $arg{'keys'} || [] };
    push @keys, map { strip_to_base_word($_) } grep { $_ && $_ !~ /nothing/ }
      split /[\s_]/, $arg{key};
    @keys = grep { $_ ne '-' && $_ ne '' && $_ ne ';' } @keys;

    my $cache_key = $as . join( '', @keys );

    if (  !$arg{helper}
        && $cache_semantic_network_get_by_key{$cache_key} )
    {

        return $cache_semantic_network_get_by_key{$cache_key};
    }

    if ( !$arg{helper} ) {
        if ( @keys > 500 ) {
            my $i            = 0;
            my $res          = [];
            my @part_of_keys = ();
            while ( my $key = pop @keys ) {
                push @part_of_keys, $key;

                if ( $i > 500 ) {
                    push @$res,
                      @{
                        semantic_network_get_by_key(
                            as     => $as,
                            'keys' => \@part_of_keys,
                            helper => 1,
                        )
                      };
                    @part_of_keys = ();
                    $i            = 0;
                }
                $i += 1;
            }

            if ($i) {
                push @$res,
                  @{
                    semantic_network_get_by_key(
                        as     => $as,
                        'keys' => \@part_of_keys,
                        helper => 1,
                    )
                  };
                @part_of_keys = ();
                $i            = -1;
            }

            return ($res);
        }
    }

    # correct keys
    foreach my $key (@keys) {
        if ( $key =~ /^[a-h][-~]?$/ ) {
            $key = '$$anything$$';
        }
    }

    map { s/[\-~]$// } @keys;
    @keys = map { $_ . '~', $_ . '-', $_ } @keys;

    # return if invalid argument
    return ( [] ) if !@keys;
    
    if ( $keys[0] eq '$$anything$$~' ) {
        push @keys, 'a', 'b';
        #die;
    }

    my $rows = 0;

    # detect number of rows!
    if ($return_anything) {
        my $sql = qq{SELECT };
        $sql .= qq{  COUNT(*)
			FROM $table_for_facts_normal
		};

        # return a random sentence
        if ($return_anything) {
            $sql .= qq{
				WHERE `verb` <> "reasonof" and `verb` <> "="
				 and `verb` <> "sein"
				 and `verb` <> "ist"
				 and `verb` <> "sind"
				 and `verb` <> "seid"
				 and `verb` <> "bin"
				 and `verb` <> "bist"
			};
        }

        my $sth;
        eval {
            local $SIG{'__DIE__'};
            $sth = $dbh->prepare($sql);
        };
        if ( !$sth ) {
            print 'nothing found with sql for: ', ( join ', ', @keys ), "\n";
            $sql = q{};
            return ( [] );
        }
        $sth->execute()
          or warn 'error executing: ', $dbh->errstr, "\n", $sql
          if ($sth);
        print "$dbh->errstr\n" if $dbh->errstr;

        ( $rows, ) = $sth->fetchrow_array;
    }

    # return value
    my @records = ();

    $sql .= qq{SELECT };
    $sql .= qq{  *
    	FROM $table_for_facts_normal
	};

    my $random_number = int( rand($rows) );

    # return a random sentence
    if ($return_anything) {
        $sql .= qq{
			WHERE `verb` <> "reasonof" and `verb` <> "="
				 and `verb` <> "sein"
				 and `verb` <> "ist"
				 and `verb` <> "sind"
				 and `verb` <> "seid"
				 and `verb` <> "bin"
				 and `verb` <> "bist"
			LIMIT } . ( $random_number - 5 ) . qq{, 10
		};

        #print $sql;
        #select undef, undef, undef, 10;
    }

    # return sentences specified by parameter
    else {
        $sql .= qq{
			WHERE 
				`verb` <> "sein" AND `verb` <> "=" AND (
		};
        if (@keys) {
            my $first_key = shift @keys;
            $sql .= qq{
				`key` = "} . $first_key . qq{"
			};
            foreach my $key (@keys) {
                next if $key =~ /nothing/;
                $sql .= qq{
					OR `key` = "} . $key . qq{"
				};
            }
            unshift @keys, $first_key;
        }
        else {
        }
        $sql .= qq{ ) };
    }

    $sql =~ s/\n//gm;
    $sql =~ s/\s+/ /gm;
    chomp $sql;
    $sql .= ";\n";

    #	print $sql;
    #	print ((join ', ', @keys), "\n");

    my $sth;
    eval {
        local $SIG{'__DIE__'};
        $sth = $dbh->prepare($sql);
    };
    if ( !$sth ) {
        print 'nothing found with sql for: ', ( join ', ', @keys ), "\n";
        $sql = q{};
        return ( [] );
    }
    $sth->execute()
      or warn 'error executing: ', $dbh->errstr, "\n", $sql
      if ($sth);
    print "$dbh->errstr\n" if $dbh->errstr;

    # form to right format
    my $data_ref;
    my $count_of_records = 0;
    if ( $as eq 'hash' ) {
        while ( $data_ref = $sth->fetchrow_arrayref ) {
            $count_of_records += 1;
            my @data = @$data_ref;
            shift @data;
            shift @data;
            shift @data;
            push @records,
              format_convert_array_to_hash(
                format_convert_sql_to_array( \@data ) );
        }
    }
    else {
        my $n = 0;
        print '$random_number: ', $random_number, "\n";
        while ( $data_ref = $sth->fetchrow_arrayref ) {
            $n += 1;

            #if ( $return_anything ) {
            #if ( $n > $random_number + 5 || $n < $random_number - 5 ) {
            #next;
            #}
            #}

            $count_of_records += 1;
            my @data = @$data_ref;
            shift @data;
            shift @data;
            push @records, [
                shift @data,

                format_convert_sql_to_array( \@data )
            ];
        }
    }

    print 'found with sql: ', $count_of_records, ', for: ',
      ( join ', ', @keys ), "\n";
    $sql = q{};

    return ( \@records );
}

sub semantic_network_key_exists {

    # parameters
    my %arg = ();
    %arg = ( %arg, @_ );

    # better names
    if ( !$arg{key} ) {
        return 0;
    }

    my $key = strip_to_base_word( $arg{key} );

    # loop
    $sql .= q{
		SELECT *
    	FROM } . $table_for_facts_normal . q{
    	WHERE `key` = "} . $key . q{"
	};

    #print $sql;

    my $sth = $dbh->prepare($sql);
    $sth->execute()
      or warn 'error executing: ', $dbh->errstr, "\n", $sql
      if ($sth);

    $sql = q{};

    return $sth->fetchrow_arrayref if $sth;
    return;
}

#use Memoize;

sub format_convert_sql_to_array {
    my ($data_ref) = @_;

    $data_ref->[3] =~ s/nothing//gm;
    $data_ref->[3] =~ s/(^[;])|([;]$)//gm;
    $data_ref->[3] ||= q{nothing};

    my @data = @$data_ref;
    my $array_ref = [ $data[0], $data[1], $data[2], $data[3], [], $data[4], ];
    for ( my $l = 5 ; $l < @data ; $l += 5 ) {
        last if !$data[ $l + 0 ] && !$data[ $l + 1 ] && !$data[ $l + 2 ];
        push @{ $array_ref->[4] },
          [
            $data[ $l + 0 ],
            $data[ $l + 1 ],
            $data[ $l + 2 ],
            $data[ $l + 3 ],
            $data[ $l + 4 ],
          ];
    }

    undef $data_ref;

    return $array_ref;
}

#memoize('format_convert_sql_to_array');

sub format_convert_array_to_hash {
    my ($fact) = @_;

    return if ref $fact ne 'ARRAY';

    my $new_fact = {
        verb       => $fact->[0],
        subj       => { name => $fact->[1] },
        obj        => { name => $fact->[2] },
        advs       => [ split /[;]/, $fact->[3] || '' ],
        subclauses => [],
        prio       => $fact->[5],
    };

    foreach my $subclause ( @{ $fact->[4] } ) {
        push @{ $new_fact->{subclauses} }, {
            verb => $subclause->[0],
            subj => { name => $subclause->[1] }
            ,    #$semantic_net->{ $subclause->[1] },
            obj => { name => $subclause->[2] }
            ,    #$semantic_net->{ $subclause->[2] },
            advs => [ split /[;]/, $subclause->[3] || q{} ],
            questionword => $subclause->[4],
        };
    }

    return $new_fact;
}

1;

