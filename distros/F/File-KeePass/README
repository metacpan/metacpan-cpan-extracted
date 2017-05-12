NAME
    File::KeePass - Interface to KeePass V1 and V2 database files

SYNOPSIS
        use File::KeePass;
        use Data::Dumper qw(Dumper);

        my $k = File::KeePass->new;

        # read a version 1 or version 2 database
        $k->load_db($file, $master_pass); # errors die

        print Dumper $k->header;
        print Dumper $k->groups; # passwords are locked

        $k->unlock;
        print Dumper $k->groups; # passwords are now visible

        $k->clear; # delete current db from memory


        my $group = $k->add_group({
            title => 'Foo',
        }); # root level group
        my $gid = $group->{'id'};

        my $group = $k->find_group({id => $gid});
        # OR
        my $group = $k->find_group({title => 'Foo'});


        my $group2 = $k->add_group({
            title => 'Bar',
            group => $gid,
            # OR group => $group,
        }); # nested group


        my $e = $k->add_entry({
            title    => 'Something',
            username => 'someuser',
            password => 'somepass',
            group    => $gid,
            # OR group => $group,
        });
        my $eid = $e->{'id'};

        my $e = $k->find_entry({id => $eid});
        # OR
        my $e = $k->find_entry({title => 'Something'});

        $k->lock;
        print $e->{'password'}; # eq undef
        print $k->locked_entry_password($e); # eq 'somepass'

        $k->unlock;
        print $e->{'password'}; # eq 'somepass'


        # save out a version 1 database
        $k->save_db("/some/file/location.kdb", $master_pass);

        # save out a version 2 database
        $k->save_db("/some/file/location.kdbx", $master_pass);

        # save out a version 1 database using a password and key file
        $k->save_db("/some/file/location.kdb", [$master_pass, $key_filename]);


        # read database from a file
        $k->parse_db($pass_db_string, $pass);

        # generate a keepass version 1 database string
        my $pass_db_string = $k->gen_db($pass);

        # generate a keepass version 2 database string
        my $pass_db_string = $k->gen_db($pass);

DESCRIPTION
    File::KeePass gives access to KeePass version 1 (kdb) and version 2
    (kdbx) databases.

    The version 1 and version 2 databases are very different in
    construction, but the majority of information overlaps and many
    algorithms are similar. File::KeePass attempts to iron out as many of
    the differences.

    File::KeePass gives nearly raw data access. There are a few utility
    methods for manipulating groups and entries. More advanced manipulation
    can easily be layered on top by other modules.

    File::KeePass is only used for reading and writing databases and for
    keeping passwords scrambled while in memory. Programs dealing with UI or
    using of auto-type features are the domain of other modules on CPAN.
    File::KeePass::Agent is one example.

METHODS
    new Takes a hashref or hash of arguments. Returns a new File::KeePass
        object. Any named arguments are added to self.

    load_db
        Takes a kdb filename, a master password, and an optional argument
        hashref. Returns the File::KeePass object on success (can be called
        as a class method). Errors die. The resulting database can be
        accessed via various methods including $k->groups.

            my $k = File::KeePass->new;
            $k->load_db($file, $pwd);

            my $k = File::KeePass->load_db($file, $pwd);

            my $k = File::KeePass->load_db($file, $pwd, {auto_lock => 0});

        The contents are read from file and passed to parse_db.

        The password passed to load_db may be a composite key in any of the
        following forms:

            "password"                   # password only
            ["password"]                 # same
            ["password", "keyfilename"]  # password and key file
            [undef, "keyfilename"]       # key file only
            ["password", \"keycontent"]  # password and reference to key file content
            [undef, \"keycontent"]       # reference to key file content only

        The key file is optional. It may be passed as a filename, or as a
        scalar reference to the contents of the key file. If a filename is
        passed it will be read in. The key file can contain any of the
        following three types:

            length 32         # treated as raw key
            length 64         # must be 64 hexidecimal characters
            any-other-length  # a SHA256 sum will be taken of the data

    save_db
        Takes a kdb filename and a master password. Stores out the current
        groups in the object. Writes attempt to write first to
        $file.new.$epoch and are then renamed into the correct location.

        You will need to unlock the db via $k->unlock before calling this
        method if the database is currently locked.

        The same master password types passed to load_db can be used here.

    parse_db
        Takes a string or a reference to a string containting an encrypted
        kdb database, a master password, and an optional argument hashref.
        Returns the File::KeePass object on success (can be called as a
        class method). Errors die. The resulting database can be accessed
        via various methods including $k->groups.

            my $k = File::KeePass->new;
            $k->parse_db($loaded_kdb, $pwd);

            my $k = File::KeePass->parse_db($kdb_buffer, $pwd);

            my $k = File::KeePass->parse_db($kdb_buffer, $pwd, {auto_lock => 0});

        The same master password types passed to load_db can be used here.

    parse_header
        Used by parse_db. Reads just the header information. Can be used as
        a basic KeePass file check. The returned hash will contain version
        => 1 or version => 2 depending upon which type of header is found.
        Can be called as a class method.

            my $head = File::KeePass->parse_header($kdb_buffer); # errors die
            printf "This is a version %d database\n", $head->{'version'};

    gen_db
        Takes a master password. Optionally takes a "groups" arrayref and a
        "headers" hashref. If groups are not passed, it defaults to using
        the currently loaded groups. If headers are not passed, a fresh set
        of headers are generated based on the groups and the master
        password. The headers can be passed in to test round trip
        portability.

        You will need to unlock the db via $k->unlock before calling this
        method if the database is currently locked.

        The same master password types passed to load_db can be used here.

    header
        Returns a hashref representing the combined current header and meta
        information for the currently loaded database.

        The following fields are present in both version 1 and version 2
        style databases (from the header):

            enc_iv               => "123456789123456", # rand
            enc_type             => "rijndael",
            header_size          => 222,
            seed_key             => "1234567890123456", # rand (32 bytes on v2)
            seed_rand            => "12345678901234567890123456789012", # rand
            rounds               => 6000,
            sig1                 => "2594363651",
            sig2                 => "3041655655", # indicates db version
            ver                  => 196608,
            version              => 1, # or 2

        The following keys will be present after the reading of a version 2
        database (from the header):

            cipher               => "aes",
            compression          => 1,
            protected_stream     => "salsa20",
            protected_stream_key => "12345678901234567890123456789012", # rand
            start_bytes          => "12345678901234567890123456789012", # rand

        Additionally, items parsed from the Meta section of a version 2
        database will be added. The following are the available fields.

            color                         => "#4FFF00",
            custom_data                   => {key1 => "val1"},
            database_description          => "database desc",
            database_description_changed  => "2012-08-17 00:30:56",
            database_name                 => "database name",
            database_name_changed         => "2012-08-17 00:30:56",
            default_user_name             => "",
            default_user_name_changed     => "2012-08-17 00:30:34",
            entry_templates_group         => "VL5nOpzlFUevGhqL71/OTA==",
            entry_templates_group_changed => "2012-08-21 14:05:32",
            generator                     => "KeePass",
            history_max_items             => 10,
            history_max_size              => 6291456, # bytes
            last_selected_group           => "SUgL30QQqUK3tOWuNKUYJA==",
            last_top_visible_group        => "dC1sQ1NO80W7klmRhfEUVw==",
            maintenance_history_days      => 365,
            master_key_change_force       => -1,
            master_key_change_rec         => -1,
            master_key_changed            => "2012-08-17 00:30:34",
            protect_notes                 => 0,
            protect_password              => 1,
            protect_title                 => 0,
            protect_url                   => 0,
            protect_username              => 0
            recycle_bin_changed           => "2012-08-17 00:30:34",
            recycle_bin_enabled           => 1,
            recycle_bin_uuid              => "SUgL30QQqUK3tOWuNKUYJA=="

        When writing a database via either save_db or gen_db, these fields
        can be set and passed along. Optionally, it is possible to pass
        along a key called reuse_header to let calls to save_db and gen_db
        automatically use the contents of the previous header.

    clear
        Clears any currently loaded database.

    auto_lock
        Default true. If true, passwords are automatically hidden when a
        database loaded via parse_db or load_db.

            $k->auto_lock(0); # turn off auto locking

    is_locked
        Returns true if the current database is locked.

    lock
        Locks the database. This moves all passwords into a protected, in
        memory, encrypted storage location. Returns 1 on success. Returns 2
        if the db is already locked. If a database is loaded via parse_db or
        load_db and auto_lock is true, the newly loaded database will start
        out locked.

    unlock
        Unlocks a previously locked database. You will need to unlock a
        database before calling save_db or gen_db.

GROUP/ENTRY METHODS
    dump_groups
        Returns a simplified string representation of the currently loaded
        database.

            print $k->dump_groups;

        You can optionally pass a match argument hashref. Only entries
        matching the criteria will be returned.

    groups
        Returns an arrayref of groups from the currently loaded database.
        Groups returned will be hierarchal. Note, groups simply returns a
        reference to all of the data. It makes no attempts at cleaning up
        the data (find_groups will make sure the data is groomed).

            my $g = $k->groups;

        Groups will look similar to the following:

            $g = [{
                 expanded => 0,
                 icon     => 0,
                 id       => 234234234, # under v1 this is a 32 bit int, under v2 it is a 16 char id
                 title    => 'Foo',
                 level    => 0,
                 entries => [{
                     accessed => "2010-06-24 15:09:19",
                     comment  => "",
                     created  => "2010-06-24 15:09:19",
                     expires  => "2999-12-31 23:23:59",
                     icon     => 0,
                     modified => "2010-06-24 15:09:19",
                     title    => "Something",
                     password => 'somepass', # will be hidden if the database is locked
                     url      => "",
                     username => "someuser",
                     id       => "0a55ac30af68149f", # v1 is any hex char, v2 is any 16 char
                 }],
                 groups => [{
                     expanded => 0,
                     icon     => 0,
                     id       => 994414667,
                     level    => 1,
                     title    => "Bar"
                 }],
             }];

    add_group
        Adds a new group to the database. Returns a reference to the new
        group. If a database isn't loaded, it begins a new one. Takes a
        hashref of arguments for the new entry including title, icon,
        expanded. A new random group id will be generated. An optional group
        argument can be passed. If a group is passed the new group will be
        added under that parent group.

            my $group = $k->add_group({title => 'Foo'});
            my $gid = $group->{'id'};

            my $group2 = $k->add_group({title => 'Bar', group => $gid});

        The group argument's value may also be a reference to a group - such
        as that returned by find_group.

    finder_tests {
        Used by find_groups and find_entries. Takes a hashref of arguments
        and returns a list of test code refs.

            {title => 'Foo'} # will check if title equals Foo
            {'title !' => 'Foo'} # will check if title does not equal Foo
            {'title =~' => qr{^Foo$}} # will check if title does matches the regex
            {'title !~' => qr{^Foo$}} # will check if title does not match the regex

    find_groups
        Takes a hashref of search criteria and returns all matching groups.
        Can be passed id, title, icon, and level. Search arguments will be
        parsed by finder_tests.

            my @groups = $k->find_groups({title => 'Foo'});

            my @all_groups_flattened = $k->find_groups({});

        The find_groups method also checks to make sure group ids are unique
        and that all needed values are defined.

    find_group
        Calls find_groups and returns the first group found. Dies if
        multiple results are found. In scalar context it returns only the
        group. In list context it returns the group, and its the arrayref in
        which it is stored (either the root level group or a sub groups
        group item).

    delete_group
        Passes arguments to find_group to find the group to delete. Then
        deletes the group. Returns the group that was just deleted.

    add_entry
        Adds a new entry to the database. Returns a reference to the new
        entry. An optional group argument can be passed. If a group is not
        passed, the entry will be added to the first group in the database.
        A new entry id will be created if one is not passed or if it
        conflicts with an existing group.

        The following fields can be passed to both v1 and v2 databases.

            accessed => "2010-06-24 15:09:19", # last accessed date
            auto_type => [{keys => "{USERNAME}{TAB}{PASSWORD}{ENTER}", window => "Foo*"}],
            binary   => {foo => 'content'}; # hashref of filename/content pairs
            comment  => "", # a comment for the system - auto-type info is normally here
            created  => "2010-06-24 15:09:19", # entry creation date
            expires  => "2999-12-31 23:23:59", # date entry expires
            icon     => 0, # icon number for use with agents
            modified => "2010-06-24 15:09:19", # last modified
            title    => "Something",
            password => 'somepass', # will be hidden if the database is locked
            url      => "http://",
            username => "someuser",
            id       => "0a55ac30af68149f", # auto generated if needed, v1 is any hex char, v2 is any 16 char
            group    => $gid, # which group to add the entry to

        For compatibility with earlier versions of File::KeePass, it is
        possible to pass in a binary and binary_name when creating an entry.
        They will be automatically converted to the hashref of
        filename/content pairs

            binary_name => "foo", # description of the stored binary - typically a filename
            binary   => "content", # raw data to be stored in the system - typically a file

            # results in
            binary => {"foo" => "content"}

        Typically, version 1 databases store their Auto-Type information
        inside of the comment. They are also limited to having only one key
        sequence per entry. File::KeePass 2+ will automatically parse
        Auto-Type values passed in the entry comment and store them out as
        the auto_type arrayref. This arrayref is serialized back into the
        comment section when saving as a version 1 database. Version 2
        databases have a separate storage mechanism for Auto-Type.

            If you passed in:
            comment => "
               Auto-Type: {USERNAME}{TAB}{PASSWORD}{ENTER}
               Auto-Type-Window: Foo*
               Auto-Type-Window: Bar*
            ",

            Will result in:
            auto_type => [{
                keys => "{USERNAME}{TAB}{PASSWORD}{ENTER}",
                window => "Foo*"
             }, {
                keys => "{USERNAME}{TAB}{PASSWORD}{ENTER}",
                window => "Bar*"
             }],

        The group argument value may be either an existing group id, or a
        reference to a group - such as that returned by find_group.

        When using a version 2 database, the following additional fields are
        also available:

            expires_enabled   => 0,
            location_changed  => "2012-08-05 12:12:12",
            usage_count       => 0,
            tags              => {},
            background_color  => '#ff0000',
            foreground_color  => '#ffffff',
            custom_icon_uuid  => '234242342aa',
            history           => [], # arrayref of previous entry changes
            override_url      => $node->{'OverrideURL'},
            auto_type_enabled => 1,
            auto_type_munge   => 0, # whether or not to attempt two channel auto typing
            protected         => {password => 1}, # indicating which strings were/should be salsa20 protected
            strings           => {'other key' => 'other value'},

    find_entries
        Takes a hashref of search criteria and returns all matching groups.
        Can be passed an entry id, title, username, comment, url, active,
        group_id, group_title, or any other entry property. Search arguments
        will be parsed by finder_tests.

            my @entries = $k->find_entries({title => 'Something'});

            my @all_entries_flattened = $k->find_entries({});

    find_entry
        Calls find_entries and returns the first entry found. Dies if
        multiple results are found. In scalar context it returns only the
        entry. In list context it returns the entry, and its group.

    delete_entry
        Passes arguments to find_entry to find the entry to delete. Then
        deletes the entry. Returns the entry that was just deleted.

    locked_entry_password
        Allows access to individual passwords for a database that is locked.
        Dies if the database is not locked.

UTILITY METHODS
    The following methods are general purpose methods used during the
    parsing and generating of kdb databases.

    now Returns the current localtime datetime stamp.

    default_exp
        Returns the string representing the default expires time of an
        entry. Will use $self->{'default_exp'} or fails to the string
        '2999-12-31 23:23:59'.

    decrypt_rijndael_cbc
        Takes an encrypted string, a key, and an encryption_iv string.
        Returns a plaintext string.

    encrypt_rijndael_cbc
        Takes a plaintext string, a key, and an encryption_iv string.
        Returns an encrypted string.

    decode_base64
        Loads the MIME::Base64 library and decodes the passed string.

    encode_base64
        Loads the MIME::Base64 library and encodes the passed string.

    unchunksum
        Parses and reassembles a buffer, reading in lengths, and checksums
        of chunks.

    decompress
        Loads the Compress::Raw::Zlib library and inflates the contents.

    compress
        Loads the Compress::Raw::Zlib library and deflates the contents.

    parse_xml
        Loads the XML::Parser library and sets up a basic parser that can
        call hooks at various events. Without the hooks, it runs similarly
        to XML::Simple::parse.

            my $data = $self->parse_xml($buffer, {
                top            => 'KeePassFile',
                force_array    => {Group => 1, Entry => 1},
                start_handlers => {Group => sub { $level++ }},
                end_handlers   => {Group => sub { $level-- }},
            });

    gen_xml
        Generates XML from the passed data structure. The output of
        parse_xml can be passed as is. Additionally hints such as __sort__
        can be used to order the tags of a node and __attr__ can be used to
        indicate which items of a node are attributes.

    salsa20
        Takes a hashref containing a salsa20 key string (length 32 or 16), a
        salsa20 iv string (length 8), number of salsa20 rounds (8, 12, or 20
        - default 20), and an optional data string. The key and iv are used
        to initialize the salsa20 encryption.

        If a data string is passed, the string is salsa20 encrypted and
        returned.

        If no data string is passed a salsa20 encrypting coderef is
        returned.

            my $encoded = $self->salsa20({key => $key, iv => $iv, data => $data});
            my $uncoded = $self->salsa20({key => $key, iv => $iv, data => $encoded});
            # $data eq $uncoded

            my $encoder = $self->salsa20({key => $key, iv => $Iv}); # no data
            my $encoded = $encoder->($data);
            my $part2   = $encoder->($more_data); # continues from previous state

    salsa20_stream
        Takes a hashref that will be passed to salsa20. Uses the resulting
        encoder to generate a more continuous encoded stream. The salsa20
        method encodes in chunks of 64 bytes. If a string is not a multiple
        of 64, then some of the xor bytes are unused. The salsa20_stream
        method maintains a buffer of xor bytes to ensure that none are
        wasted.

            my $encoder = $self->salsa20_stream({key => $key, iv => $Iv}); # no data
            my $encoded = $encoder->("1234");   # calls salsa20->()
            my $part2   = $encoder->("1234");   # uses the same pad until 64 bytes are used

OTHER METHODS
    _parse_v1_header
    _parse_v1_body
    _parse_v1_groups
    _parse_v1_entries
    _parse_v1_date
        Utilities used for parsing version 1 type databases.

    _parse_v2_header
    _parse_v2_body
    _parse_v2_date
        Utilities used for parsing version 2 type databases.

    _gen_v1_db
    _gen_v1_header
    _gen_v1_date
        Utilities used to generate version 1 type databases.

    _gen_v2_db
    _gen_v2_header
    _gen_v2_date
        Utilities used to generate version 2 type databases.

    _master_key
        Takes the password and parsed headers. Returns the master key based
        on database type.

ONE LINERS
    (Long one liners)

    Here is a version 1 to version 2, or version 2 to version 1 converter.
    Simply change the extension of the two files. Someday we will include a
    kdb2kdbx utility to do this for you.

        perl -MFile::KeePass -e 'use IO::Prompt; $p="".prompt("Pass:",-e=>"*",-tty); File::KeePass->load_db(+shift,$p,{auto_lock=>0})->save_db(+shift,$p)' ~/test.kdb ~/test.kdbx

        # OR using graphical prompt
        perl -MFile::KeePass -e 'chop($p=`zenity --password`); File::KeePass->load_db(+shift,$p,{auto_lock=>0})->save_db(+shift,$p)' ~/test.kdbx ~/test.kdb

        # OR using pure perl (but echoes password)
        perl -MFile::KeePass -e 'print "Pass:"; chop($p=<STDIN>); File::KeePass->load_db(+shift,$p,{auto_lock=>0})->save_db(+shift,$p)' ~/test.kdbx ~/test.kdb

    Dumping the XML from a version 2 database.

        perl -MFile::KeePass -e 'chop($p=`zenity --password`); print File::KeePass->load_db(+shift,$p,{keep_xml=>1})->{xml_in},"\n"' ~/test.kdbx

    Outlining group information.

        perl -MFile::KeePass -e 'chop($p=`zenity --password`); print File::KeePass->load_db(+shift,$p)->dump_groups' ~/test.kdbx

    Dumping header information

        perl -MFile::KeePass -MData::Dumper -e 'chop($p=`zenity --password`); print Dumper +File::KeePass->load_db(+shift,$p)->header' ~/test.kdbx

BUGS
    Only Rijndael is supported when using v1 databases.

    This module makes no attempt to act as a password agent. That is the job
    of File::KeePass::Agent. This isn't really a bug but some people will
    think it is.

    Groups and entries don't have true objects associated with them. At the
    moment this is by design. The data is kept as plain boring data.

SOURCES
    Knowledge about the algorithms necessary to decode a KeePass DB v1
    format was gleaned from the source code of keepassx-0.4.3. That source
    code is published under the GPL2 license. KeePassX 0.4.3 bears the
    copyright of

        Copyright (C) 2005-2008 Tarek Saidi <tarek.saidi@arcor.de>
        Copyright (C) 2007-2009 Felix Geyer <debfx-keepassx {at} fobos.de>

    Knowledge about the algorithms necessary to decode a KeePass DB v2
    format was gleaned from the source code of keepassx-2.0-alpha1. That
    source code is published under the GPL2 or GPL3 license. KeePassX
    2.0-alpha1 bears the copyright of

        Copyright: 2010-2012, Felix Geyer <debfx@fobos.de>
                   2011-2012, Florian Geyer <blueice@fobos.de>

    The salsa20 algorithm is based on
    http://cr.yp.to/snuffle/salsa20/regs/salsa20.c which is listed as Public
    domain (D. J. Bernstein).

    The ordering and layering of encryption/decryption algorithms of
    File::KeePass are of derivative nature from KeePassX and could not have
    been created without this insight - though the perl code is from
    scratch.

AUTHOR
    Paul Seamons <paul@seamons.com>

LICENSE
    This module may be distributed under the same terms as Perl itself.

