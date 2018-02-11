use strict;
use warnings;

use Devel::Chitin::OpTree;
use Devel::Chitin::Location;
use Test::More tests => 33;

use Fcntl qw(:flock :DEFAULT SEEK_SET SEEK_CUR SEEK_END);
use POSIX qw(:sys_wait_h);
use Socket;
use Scalar::Util qw(blessed);

subtest construction => sub {
    plan tests => 5;

    sub scalar_assignment {
        my $a = 1;
    }

    my $ops = _get_optree_for_sub_named('scalar_assignment');
    ok($ops, 'create optree');
    my $count = 0;
    my $last_op;
    $ops->walk_inorder(sub { $last_op = shift; $count++ });
    ok($count > 1, 'More than one op is part of scalar_assignment');

    is($ops->deparse, '$a = 1', 'scalar_assignment');

    sub multi_statement_scalar_assignment {
        my $a = 1;
        my $b = 2;
    }
    is(_get_optree_for_sub_named('multi_statement_scalar_assignment')->deparse,
        join("\n", q($a = 1;), q($b = 2)),
        'multi_statement_scalar_assignment');

    is($last_op->root_op, $ops, 'root_op property');
};

subtest 'assignment' => sub {
    _run_tests(
        list_assignment => join("\n", q(my @a = (1, 2);),
                                      q(our @b = (3, 4);),
                                      q(@a = @b;),
                                      q(my($a, $b) = (@a, @b);),
                                      q(@a = (@b, @a)),
            ),
        list_index_assignment => join("\n", q(my(@the_list, $idx);),
                                            q($the_list[2] = 'foo';),
                                            q($the_list[$idx] = 'bar')),

        list_slice_assignment => join("\n", q(my(@the_list, $idx);),
                                            q(my @other_list;),
                                            q(@the_list[1, $idx, 3, @other_list] = @other_list[1, 2, 3])),
        # These hash assigments are done with aassign, so there's no way to
        # tell that the lists would look better as ( one => 1, two => 2 )
        hash_assignment => join("\n",   q(my %a = ('one', 1, 'two', 2);),
                                        q(our %b = ('three', 3, 'four', 4);),
                                        q(%a = %b;),
                                        q(%a = (%b, %a))),
        hash_slice_assignment => join("\n", q(my(%the_hash, @indexes);),
                                            q(@the_hash{'1', 'key', @indexes} = (1, 2, 3))),

        scalar_ref_assignment => join("\n", q(my $a = 1;),
                                            q(our $b = \$a;),
                                            q($$b = 2)),

        array_ref_assignment => join("\n",  q(my $a = [1, 2];),
                                            q(@$a = (1, 2))),
        array_ref_slice_assignment => join("\n",    q(my($list, $other_list);),
                                                    q(@$list[1, @$other_list] = (1, 2, 3))),

        hash_ref_assignment => join("\n",   q(my $a = {1 => 1, two => 2};),
                                            q(%$a = ('one', 1, 'two', 2))),
        hasf_ref_slice_assignment => join("\n", q(my $hash = {};),
                                                q(my @list;),
                                                q(@$hash{'one', @list, 'last'} = @list)),
        list_slice => join("\n",    q(my $a = (1, 2, 3)[1];),
                                    q($a = (caller(1))[2, 3])),
    );
};

subtest 'conditional' => sub {
    _run_tests(
        'num_lt' => join("\n",  q(my $a = 1;),
                                q(my $result = $a < 5)),
        'num_gt' => join("\n",  q(my $a = 1;),
                                q(my $result = $a > 5)),
        'num_eq' => join("\n",  q(my $a = 1;),
                                q(my $result = $a == 5)),
        'num_ne' => join("\n",  q(my $a = 1;),
                                q(my $result = $a != 5)),
        'num_le' => join("\n",  q(my $a = 1;),
                                q(my $result = $a <= 5)),
        'num_cmp' => join("\n", q(my $a = 1;),
                                q(my $result = $a <=> 5)),
        'num_ge' => join("\n",  q(my $a = 1;),
                                q(my $result = $a >= 5)),
        'str_lt' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a lt 'five')),
        'str_gt' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a gt 'five')),
        'str_eq' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a eq 'five')),
        'str_ne' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a ne 'five')),
        'str_le' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a le 'five')),
        'str_ge' => join("\n",  q(my $a = 'one';),
                                q(my $result = $a ge 'five')),
        'str_cmp' => join("\n", q(my $a = 1;),
                                q(my $result = $a cmp 5)),
    );
};

subtest 'subroutine call' => sub {
    _run_tests(
        'call_sub' => join("\n",    q(foo(1, 2, 3))),
        'call_subref' => join("\n", q(my $a;),
                                    q($a->(1, 'two', 3))),
        'call_subref_from_array' => join("\n",  q(my @a;),
                                                q($a[0]->(1, 'two', 3))),
        'call_sub_from_package' => q(Some::Other::Package::foo(1, 2, 3)),
        'call_class_method_from_package' => q(Some::Other::Package->foo(1, 2, 3)),
        'call_instance_method' => join("\n",    q(my $obj;),
                                                q($obj->foo(1, 2, 3))),
        'call_instance_variable_method' => join("\n",   q(my($obj, $method);),
                                                        q($obj->$method(1, 2, 3))),
        'call_class_variable_method' => join("\n",  q(my $method;),
                                                    q(Some::Other::Package->$method(1, 2, 3))),
        'call_with_amp' => join("\n",   q(&foo(1, 2, 3);),
                                        q(&foo();),
                                        q(&foo)),
        call_without_paren => join("\n",    q(my $a = _get_optree_for_sub_named;),
                                            q($a = _get_optree_for_sub_named 1, 2, 3)),
    );
};

subtest 'eval' => sub {
    _run_tests(
        'const_string_eval' => q(eval('this is a string')),
        'var_string_eval' => join("\n", q(my $a;),
                                        q(eval();),
                                        q(eval($a))),
        'block_eval' => join("\n",  q(my $a;),
                                    q(eval {),
                                   qq(\tdo_something();),
                                   qq(\t\$a),
                                    q(})),
    );
};

subtest 'string functions' => sub {
    _run_tests(
        crypt_fcn => join("\n", q(my $a;),
                                q(crypt($a, 'salt'))),
        index_fcn => join("\n", q(my $a;),
                                q($a = index($a, 'foo');),
                                q(index($a, 'foo', 1))),
        rindex_fcn  => join("\n",   q(my $a;),
                                    q($a = rindex($a, 'foo');),
                                    q(index($a, 'foo', 1))),
        substr_fcn  => join("\n",   q(my $a;),
                                    q($a = substr($a, 1, 2, 'foo');),
                                    q(substr($a, 2, 3) = 'bar';),  # doubled because the first one triggers an optimized-out
                                    q(substr($a, 2, 3) = 'bar')),  # sassign with a single child
        sprintf_fcn => join("\n",   q(my $a;),
                                    q($a = sprintf($a, 1, 2, 3))),
        quote_qq    => join("\n",   q(my $a = 'hi there';),
                                    q(my $b = qq(Joe, $a, this is a string blah blah\n\cP\x{1f});),
                                    q($b = $a . $a;),
                                    q($b = qq($b $b))),
        pack_fcn  => join("\n", q(my $a;),
                                q($a = pack($a, 1, 2, 3))),
        unpack_fcn => join("\n",q(my $a;),
                                q($a = unpack('%32b', $a);),
                                q($a = unpack($a, $a))),
        reverse_fcn => join("\n",   q(my $a;),
                                    q($a = reverse(@_);),
                                    q($a = reverse($a);),
                                    q(scalar(reverse(@_));),
                                    q(my @a;),
                                    q(@a = reverse(@_);),
                                    q(@a = reverse(@a))),
        tr_operator => no_warnings('misc'),
                       join("\n",   q(my $a;),
                                    q($a = tr/$a/zyxw/cds)),
        quotemeta_fcn => join("\n", q(my $a;),
                                    q($a = quotemeta();),
                                    q($a = quotemeta($a);),
                                    q(quotemeta($a))),
        vec_fcn => join("\n",       q(my $a = vec('abcdef', 1, 4);),
                                    q(vec($a, 2, 2) = 4)),
        formline_fcn => join("\n",  q(my($a, $b);),
                                    q($a = formline('one', $b, 'three'))),

        concat_op => join("\n", q(my $a;),
                                q($a = qq(abc$a);),
                                q(my $b = qq(123$a) . $a . qq(456$a) . $a . '789')),

        map { ( "${_}_dfl"      => "$_()",
                "${_}_to_var"   => join("\n",   q(my $a;),
                                                "\$a = $_()"),
                "${_}_on_val"   => join("\n",   q(my $a;),
                                                "$_(\$a)")
              )
            } qw( chomp chop chr hex lc lcfirst uc ucfirst length oct ord ),
    );
};

subtest regex => sub {
    _run_tests(
        anon_regex => join("\n",    q(my $a = qr/abc\w(\s+)/ims;),
                                    q(my $b = qr/abc),
                                    q(           \w),
                                    q(           $a),
                                    q(           (\s+)/iox)),
        match       => join("\n",   q(m/abc/;),
                                    q(our $string = '123';),
                                    q($string =~ m/abc/;),
                                    q(my $rx = qr/def/;),
                                    q(my($b) = $a !~ m/abc$rx/i;),
                                    q(my($c) = m/$rx def/x;),
                                    q($c = $1)),
        substitute  => join("\n",   q(s/abc/def/i;),
                                    q(my $a;),
                                    q($a =~ s/abc/def/;),
                                    q($a =~ s/abc/def$a/;),
                                    q(my $rx = qr/def/;),
                                    q(s/abd $rx/def/x;),
                                    q($a =~ s/abd $rx/def/x)),
        pos_fcn => join("\n",   q(my $a = pos();),
                                q($a = pos($a);),
                                q(pos($a) = 123)),
        split_fcn => join("\n",     q(my $a;),
                                    q(my $size = split(/abc/, $a);),
                                    q(my $rx;),
                                    q(my @strings = split(/$rx/, $a, 1);),
                                    q(@strings = split(/a/, $a);),
                                    q(@strings = split(//, $a);),
                                    q(@strings = split(/ /, $a);),
                                    q(my($v1, $v2) = split(/$rx/, $a, 3))),  # the 3 is implicit
    );
};

subtest numeric => sub {
    _run_tests(
        atan2_func => join("\n",    q(my($a, $b);),
                                    q($a = atan2($a, $b))),
        map { ( "${_}_func" => join("\n", q(my $a;),
                                        "\$a = $_();",
                                        "\$a = $_(\$a);",
                                        "$_(\$a)")
              )
            } qw(abs cos exp int log rand sin sqrt srand),
    );
};

subtest 'array functions' => sub {
    _run_tests(
        pop_fcn => join("\n",   q(my($a, @list);),
                                q($a = pop(@list);),
                                q(pop(@list);),
                                q($a = pop)),
        push_fcn => join("\n",  q(my($a, @list);),
                                q(push(@list, 1, 2, 3);),
                                q($a = push(@list, 1))),
        shift_fcn => join("\n", q(my($a, @list);),
                                q($a = shift(@list);),
                                q(shift(@list);),
                                q($a = shift)),
        unshift_fcn => join("\n",   q(my($a, @list);),
                                    q(unshift(@list, 1, 2, 3);),
                                    q($a = unshift(@list, 1))),
        splice_fcn => join("\n",q(my($a, @list, @rv);),
                                q($a = splice(@list);),
                                q(@rv = splice(@list, 1);),
                                q(@rv = splice(@list, 1, 2);),
                                q(@rv = splice(@list, 1, 2, @rv);),
                                q(@rv = splice(@list, 1, 2, 3, 4, 5))),
        array_len => join("\n", q(my($a, @list, $listref);),
                                q($a = $#list;),
                                q($a = $#$listref;),
                                q($a = scalar(@list))),
        join_fcn => join("\n",  q(my($a, @list);),
                                q($a = join(',', 2, $a, 4);),
                                q($a = join("\n", 2, $a, 4);),
                                q($a = join(1, @list);),
                                q(join(@list))),
    );
};

subtest 'sort/map/grep' => sub {
    _run_tests(
        map_fcn => join("\n",  q(my($a, @list);),
                                q(map(chr(), $a, $a);),
                                q(map(chr(), @list);),
                                q(map { chr() } ($a, $a);),
                                q(map { chr() } @list)),
        grep_fcn => join("\n",  q(my($a, @list);),
                                q(grep(m/a/, $a, $a);),
                                q(grep(m/a/, @list);),
                                q(grep { m/a/ } ($a, $a);),
                                q(grep { m/a/ } @list)),
        sort_fcn => join("\n",  q(my(@a, $subref, $val);),
                                q(@a = sort @a;),
                                q(@a = sort ($val, @a);),
                                q(@a = sort { 1 } @a;),
                                q(@a = sort { ; } @a;),
                                q(@a = sort { $a <=> $b } @a;),
                                q(@a = sort { $b <=> $a } @a;),
                                q(@a = sort { $b cmp $a } @a;),
                                q(@a = reverse(sort { $b cmp $a } @a);),
                                q(@a = sort scalar_assignment @a;),
                                q(@a = sort $subref @a)),
    );
};

subtest 'hash functions' => sub {
    _run_tests(
        delete_hash => join("\n",   q(our %ourhash;),
                                    q(my %myhash;),
                                    q(my $a = delete($ourhash{'foo'});),
                                    q(my @a = delete(@myhash{'foo', 'bar'});),
                                    q(@a = delete(@ourhash{@a});),
                                    q(delete(@myhash{@a});),
                                    q(delete(local @ourhash{@a});),
                                    q(delete(local $myhash{'foo'}))),
        delete_array => join("\n",  q(our @ourarray;),
                                    q(my @myarray;),
                                    q(my $a = delete($ourarray[1]);),
                                    q(my @a = delete(@myarray[1, 2]);),
                                    q(@a = delete(@myarray[@a]);),
                                    q(delete(local @ourarray[@a]);),
                                    q(delete(local $myarray[3]))),
        exists_hash => join("\n",   q(my %hash;),
                                    q(my $a = exists($hash{'foo'}))),
        exists_array => join("\n",  q(my @array;),
                                    q(my $a = exists($array[1]))),
        exists_sub => q(my $a = exists(&scalar_assignment)),
        each_fcn => join("\n",  q(my %h;),
                                q(my($k, $v) = each(%h))),
        keys_fcn => join("\n",  q(my %h;),
                                q(my @keys = keys(%h))),
        values_fcn => join("\n",q(my %h;),
                                q(my @vals = values(%h))),
    );
};

subtest 'user/group/network info' => sub {
    _run_tests(
        getgrent_fcn => join("\n",  q(my $a = getgrent();),
                                    q($a = getgrent())),
        endhostent_fcn =>   q(endhostent()),
        endnetent_fcn =>    q(endnetent()),
        endpwent_fcn =>     q(endpwent()),
        endprotent_fcn =>   q(endprotent()),
        endservent_fcn =>   q(endservent()),
        setpwent_fcn =>     q(setpwent()),
        endgrent_fcn =>     q(endgrent()),
        setgrent_fcn =>     q(setgrent()),
        sethostent_fcn =>   q(sethostent(1)),
        setnetent_fcn =>    q(setnetent(0)),
        setprotoent_fcn =>  q(setprotoent(undef)),
        setservent_fcn =>   q(setservent(1)),
        getlogin_fcn =>     q(my $a = getlogin()),
        getgrgid_fcn => join("\n",  q(my $gid;),
                                    q(my $a = getgrgid($gid))),
        getgrnam_fcn => join("\n",  q(my $name;),
                                    q(my $a = getgrnam($name))),
        getpwent_fcn => join("\n",  q(my $name = getpwent();),
                                    q(my @info = getpwent();),
                                    q(my($n, $pass, $uid, $gid) = getpwent())),
        gethostent_fcn => join("\n",q(my $name = gethostent();),
                                    q(my @info = gethostent())),
        getnetent_fcn => join("\n", q(my $name = getnetent();),
                                    q(my @info = getnetent())),
        getprotoent_fcn => join("\n",   q(my $name = getprotoent();),
                                        q(my @info = getprotoent())),
        getservent_fcn => join("\n",q(my $name = getservent();),
                                    q(my @info = getservent())),
        getpwnam_fcn => join("\n",  q(my $gid = getpwnam('root');),
                                    q(my @info = getpwnam('root');),
                                    q(my($name, $pass, $uid, $g) = getpwnam('root'))),
        getpwuid_fcn => join("\n",  q(my $name = getpwuid(0);),
                                    q(my @info = getpwuid(0);),
                                    q(my($n, $pass, $uid, $gid) = getpwuid(0))),
        gethostbyaddr_fcn => join("\n", q(my $name = gethostbyaddr(inet_aton('127.1'), AF_INET);),
                                        q(my @info = gethostbyaddr(inet_aton('127.2'), AF_UNIX))),
        gethostbyname_fcn => join("\n", q(my $addr = gethostbyname('example.org');),
                                        q(my @info = gethostbyname('example.com'))),
        getnetbyaddr_fcn => join("\n",  q(my $name = getnetbyaddr(inet_aton('127.1'), AF_INET);),
                                        q(my @info = getnetbyaddr(inet_aton('127.2'), AF_UNIX))),
        getnetbyname_fcn => join("\n",  q(my $addr = getnetbyname('example.org');),
                                        q(my @info = getnetbyname('example.com'))),
        getprotobyname_fcn => join("\n",q(my $num = getprotobtname('tcp');),
                                        q(my @info = getprotobyname('udp'))),
        getprotobynumber_fcn => join("\n",q(my $a;),
                                        q(my $num = getprotobynumber($a);),
                                        q(my @info = getprotobynumber($a))),
        getservbyname_fcn => join("\n", q(my $port = getservbyname('ftp', 'tcp');),
                                        q(my @info = getservbyname('echo', 'udp'))),
        getservbyport_fcn => join("\n", q(my $port = getservbyport(21, 'tcp');),
                                        q(my @info = getservbyport(7, 'udp'))),
    );
};

subtest 'I/O' => sub {
    _run_tests(
        binmode_fcn => join("\n",   q(binmode(F);),
                                    q(binmode(*F, ':raw');),
                                    q(binmode(F, ':crlf');),
                                    q(my $fh;),
                                    q(binmode($fh);),
                                    q(binmode(*$fh, ':raw');),
                                    q(binmode($fh, ':crlf'))),
        close_fcn => join("\n",     q(close(F);),
                                    q(close(*G);),
                                    q(my $f;),
                                    q(close($f);),
                                    q(close(*$f);),
                                    q(close())),
        closedir_fcn => join("\n",  q(closedir(D);),
                                    q(closedir(*D);),
                                    q(my $d;),
                                    q(closedir($d);),
                                    q(closedir(*$d))),
        dbmclose_fcn => join("\n",  q(my %h;),
                                    q(dbmclose(%h))),
        dbmopen_fcn => join("\n",   q(my %h;),
                                    q(dbmopen(%h, '/some/path/name', 0666))),
        die_fcn => q(die('some list', 'of things', 1, 1.234)),
        warn_fcn => join("\n",  q(warn('some list', 'of things', 1, 1.234);),
                                q(warn())),
        eof_fcn => join("\n",   q(my $a = eof(F);),
                                q($a = eof(*F);),
                                q(my $f;),
                                q($a = eof($f);),
                                q($a = eof(*$f);),
                                q($a = eof;),
                                q($a = eof())),
        fileno_fcn => join("\n",    q(my $a = fileno(F);),
                                    q(my $f;),
                                    q($a = fileno(*$f))),
        flock_fcn => join("\n",     q(my $a = flock(F, LOCK_SH | LOCK_NB);),
                                    q($a = flock(*F, LOCK_EX | LOCK_NB);),
                                    q(my $f;),
                                    q($a = flock($f, LOCK_UN);),
                                    q($a = flock(*$f, LOCK_UN | LOCK_NB))),
        getc_fcn => join("\n",      q(my $a = getc(F);),
                                    q($a = getc())),
        print_fcn => join("\n",     q(my $a = print();),
                                    q(print('foo bar', 'baz', "\n");),
                                    q(print F ('foo bar', 'baz', "\n");),
                                    q(print "Hello\n";),
                                    q(print F "Hello\n";),
                                    q(my $f;),
                                    q(print { $f } ('foo bar', 'baz', "\n");),
                                    q(print { *$f } ('foo bar', 'baz', "\n"))),
        printf_fcn => join("\n",    q(printf F ($a, 'foo', 'bar');),
                                    q(printf($a, 'foo', 'bar'))),
        read_fcn => join("\n",      q(my($fh, $buf);),
                                    q(my $bytes = read(F, $buf, 10);),
                                    q(read(*$fh, $buf, 10, 5);),
                                    q(read(*F, $buf, 10, -5))),
        sysread_fcn => join("\n",   q(my($fh, $buf);),
                                    q(my $bytes = sysread(F, $buf, 10);),
                                    q(sysread(*$fh, $buf, 10, 5);),
                                    q(sysread(*F, $buf, 10, -5))),
        syswrite_fcn => join("\n",  q(my($fh, $buf);),
                                    q(my $bytes = syswrite(F, $buf, 10, 5);),
                                    q($bytes = syswrite(*F, $buf, 10);),
                                    q(syswrite($fh, $buf);),
                                    q(syswrite(*$fh, $buf))),
        readdir_fcn => join("\n",   q(my $d;),
                                    q(my $dir = readdir(D);),
                                    q($dir = readdir(*D);),
                                    q($dir = readdir($d);),
                                    q($dir = readdir(*$d))),
        readline_fcn => join("\n",  q(my $line = <ARGV>;),
                                    q($line = readline(*F);),
                                    q($line = <F>;),
                                    q(my $fh;),
                                    q(my @lines = readline($fh);),
                                    q(@lines = readline(*$fh))),
        rewinddir_fcn =>    q(rewinddir(D)),
        seekdir_fcn =>      q(seekdir(D, 10)),
        seek_fcn => join("\n",      q(my $a = seek(F, 10, SEEK_CUR);),
                                    q(my $fh;),
                                    q(seek($fh, -10, SEEK_END);),
                                    q(seek(*$fh, 0, SEEK_SET))),
        sysseek_fcn => join("\n",   q(my $a = sysseek(F, 10, SEEK_CUR);),
                                    q(my $fh;),
                                    q(sysseek($fh, -10, SEEK_END);),
                                    q(sysseek(*$fh, 0, SEEK_SET))),
        tell_fcn => join("\n",      q(my $a = tell(F);),
                                    q($a = tell(*F);),
                                    q($a = tell();),
                                    q(my $fh;),
                                    q($a = tell($fh);),
                                    q($a = tell(*$fh))),
        telldir_fcn => join("\n",   q(my $a = telldir(D);),
                                    q($a = telldir(*D);),
                                    q(my $dh;),
                                    q($a = telldir($dh);),
                                    q($a = telldir(*$dh))),
        syscall_fcn => join("\n",   q(my $a = syscall(1, 2, 3);),
                                    q(my $str = 'foo';),
                                    q($a = syscall(4, $str, 5))),
        truncate_fcn => join("\n",  q(my $a = truncate(F, 10);),
                                    q($a = truncate(*F, 11);),
                                    q(my($fh, %h);),
                                    q(truncate($fh, 12);),
                                    q(truncate($h{'foo'}, 14))),
        write_fcn => join("\n",     q(write(F);),
                                    q(write(*F);),
                                    q(my $fh;),
                                    q(write($fh);),
                                    q(write())),
        select_fh => join("\n",     q(my $fh = select();),
                                    q(select(F);),
                                    q(select(*F);),
                                    q(select($fh);),
                                    q(select(*$fh))),
        select_sycall => join("\n", q(my($found, $time) = select(*F, 1, 2, 3);),
                                    q($found = select(*F, 1, 2, 3);),
                                    q(my $fh;),
                                    q(($found, $time) = select($fh, 1, 2, 3);),
                                    q($found = select(*$fh, 1, 2, 3))),
    );
};

subtest 'files' => sub {
    _run_tests(
        file_tests =>   join("\n",  q(my $fh;),
                                    q(my $a = -r *F;),
                                    q($a = -w '/some/path/name';),
                                    q($a = -x $fh;),
                                    q($a = -o;),
                                    q($a = -R _;),
                                    q($a = -W $fh;),
                                    q($a = -X *F;),
                                    q($a = -O '/some/file/name';),
                                    q($a = -e;),
                                    q($a = -z _;),
                                    q($a = -s '/some/file/name';),
                                    q($a = -f $fh;),
                                    q($a = -d *F;),
                                    q($a = -l;),
                                    q($a = -p _;),
                                    q($a = -S *F;),
                                    q($a = -b '/some/file/name';),
                                    q($a = -c $fh;),
                                    q($a = -t _;),
                                    q($a = -u;),
                                    q($a = -g $fh;),
                                    q($a = -k *F;),
                                    q($a = -T '/some/file/name';),
                                    q($a = -B;),
                                    q($a = -M _;),
                                    q($a = -A '/some/file/name';),
                                    q($a = -C $fh)),
        chdir_expr => join("\n",    q(my $a = chdir('/some/path/name');),
                                    q($a = chdir())),
        chdir_fh => q(chdir(*F)),
        chmod_fcn => join("\n",     q(my $a = chmod(0755, '/some/file/name', '/other/file');),
                                    q(chmod(04322, 'foo'))),
        chown_fcn => join("\n",     q(my $a = chown(0, 3, '/some/file/name', '/other/file');),
                                    q(chown(1, 999, 'foo'))),
        chroot_fcn => join("\n",    q(my $a = chroot('/some/file/name');),
                                    q(chroot())),
        fcntl_fcn => join("\n",     q(my $a = fcntl(F, 1, 2);),
                                    q(fcntl(*F, 2, 'foo');),
                                    q(my($fh, $buf);),
                                    q(fcntl($fh, 3, $buf);),
                                    q(fcntl(*$fh, 4, 0))),
        glob_fcn =>     join("\n",  q(my @files = glob('some *patterns{one,two}');),
                                    q(my $file = glob('*.c');),
                                    q($file = glob('*.h'))),
        ioctl_fcn => join("\n",     q(my($a, $fh);),
                                    q(my $rv = ioctl(F, 1, $a);),
                                    q($rv = ioctl(*F, 2, $a);),
                                    q(ioctl($fh, 3, $a);),
                                    q($rv = ioctl(*$fh, 4, $a))),
        link_fcn => join("\n",  q(my $a = link('/old/path', '/new/path');),
                                q($a = link('/other_file', 'new_link');),
                                q($a = link($a, '/foo/bar'))),
        mkdir_fcn => join("\n", q(my $a = mkdir('/some/path', 0755);),
                                q($a = mkdir('/other/path'))),
        open_fcn => join("\n",  q(my $rv = open(F, 'some/path');),
                                q($rv = open(*F, 'r', '/some/path');),
                                q(open(F);),
                                q(open(my $fh, '|-', '/some/command', '-a', '-b');),
                                q(open(*$fh, '>:raw:perlio:encoding(utf-16le):crlf', 'filename.ext'))),
        opendir_fcn => join("\n",   q(my $rv = opendir(D, '/path/name');),
                                    q($rv = opendir(*D, '/path/name');),
                                    q($rv = opendir(my $dh, '/path/name');),
                                    q($rv = opendir(*$dh, '/path/name'))),
        readlink_fcn => join("\n",  q(my $rv = readlink('/path/name');),
                                    q(readlink())),
        rename_fcn =>   q(my $rv = rename('/old/path/name', '/new/name')),
        rmdir_fcn => join("\n", q(my $rv = rmdir('/path/name');),
                                q($rv = rmdir())),
        stat_fcn => join("\n",  q(my @rv = stat(F);),
                                q(@rv = stat(*F);),
                                q(@rv = stat(_);),
                                q(my $fh;),
                                q(my($dev, $ino, undef, $nlink) = stat($fh);),
                                q(@rv = stat(*$fh);),
                                q(stat();),
                                q(stat('/path/to/file'))),
        lstat_fcn => join("\n", q(my @rv = lstat(F);),
                                q(@rv = lstat(*F);),
                                q(@rv = lstat(_);),
                                q(my $fh;),
                                q(my($dev, $ino, undef, $nlink) = lstat($fh);),
                                q(@rv = lstat(*$fh);),
                                q(lstat();),
                                q(lstat('/path/to/file'))),
        symlink_fcn => join("\n",   q(my $rv = symlink('/file/name', '/link/name');),
                                    q($rv = symlink('/other_file', 'new_link'))),
        sysopen_fcn => join("\n",   q(my $rv = sysopen(F, '/path/name', O_RDONLY);),
                                    q($rv = sysopen(*F, '/path_name', O_RDWR | O_TRUNC);),
                                    q(sysopen(my $fh, '/path/name', O_WRONLY | O_CREAT, 0777);),
                                    q(my $mode;),
                                    q(sysopen($fh, '/path/name', O_WRONLY | O_CREAT, $mode);),
                                    q(sysopen(*$fh, '/path/name', O_WRONLY | O_CREAT | O_EXCL);),
                                    q(my $flags;),
                                    q(sysopen($fh, '/path/name', $flags))),
        umask_fcn => join("\n", q(my $mask = umask();),
                                q(umask(0775))),
        unlink_fcn => join("\n",    q(my $rv = unlink('/path/name', '/file/name');),
                                    q(my($a, $b);),
                                    q($rv = unlink($a, $b))),
        utime_fcn => join("\n",     q(my $rv = utime(undef, undef, '/path/name', '/file_name');),
                                    q(my($a, $b);),
                                    q($rv = utime(123, 456, $a, $b))),
    );
};

subtest operators => sub {
    _run_tests(
        undef_op => join("\n",  q(my $a = undef;),
                                q(undef($a);),
                                q(my(@a, %a);),
                                q(undef($a[1]);),
                                q(undef($a{'foo'});),
                                q(undef(@a);),
                                q(undef(%a);),
                                q(undef(&some::function::name))),
        defined_op => join("\n",q(my $a;),
                                q($a = defined($a);),
                                q($a = defined())),
        scalar_op => join("\n", q(my($a, @a);),
                                q($a = scalar(@a);),
                                q($a = scalar($a))),
        add_op => join("\n",    q(my($a, $b);),
                                q($a = $a + $b;),
                                q($b = $a + $b + 1)),
        sub_op => join("\n",    q(my($a, $b);),
                                q($a = $a - $b;),
                                q($b = $a - $b - 1)),
        mul_op => join("\n",    q(my($a, $b);),
                                q($a = $a * $b;),
                                q($b = $a * $b * 2)),
        div_op => join("\n",    q(my($a, $b);),
                                q($a = $a / $b;),
                                q($b = $a / $b / 2)),
        mod_op => join("\n",    q(my($a, $b);),
                                q($a = $a % $b;),
                                q($b = $a % $b % 2)),
        preinc_op => join("\n", q(my $a = 4;),
                                q(my $b = ++$a)),
        postinc_op => join("\n",q(my $a = 4;),
                                q(my $b = $a++)),
        bin_negate => join("\n",q(my $a = 3;),
                                q(my $b = ~$a;),
                                q($a = ~$b)),
        deref_op => join("\n",  q(my $a = 1;),
                                q(our $b = 2;),
                                q($a = $a->{'foo'};),
                                q($a = $b->{'foo'}->[2];),
                                q($a = @{ $a->{'foo'}->[3]->{'bar'} };),
                                q($a = %{ $b->[2]->{'foo'}->[4] };),
                                q($a = ${ $a->{'foo'}->[5]->{'bar'} };),
                                q($a = *{ $b->[$a]->{'foo'}->[5] };),
                                q($a = $$a;),
                                q($b = $$b)),
        pow_op => join("\n",    q(my $a;),
                                q($a = 3 ** $a)),
        log_negate => join("\n",q(my $a = 1;),
                                q($a = !$a)),
        repeat => join("\n",    q(my $a;),
                                q($a = $a x 10;),
                                q(my @a = (1, 2, 3) x $a)),
        shift_left => join("\n",q(my $a;),
                                q($a = $a << 1;),
                                q($a = $a << $a)),
        shift_right => join("\n",q(my $a;),
                                q($a = $a >> 1;),
                                q($a = $a >> $a)),
        bit_and => join("\n",   q(my $a;),
                                q($a = $a & 1;),
                                q(my $b = $a & 3 & $a)),
        bit_or => join("\n",    q(my $a;),
                                q($a = $a | 1;),
                                q(my $b = $a | 3 | $a)),
        bit_xor => join("\n",   q(my $a;),
                                q($a = $a ^ 1)),
        log_and => join("\n",   q(my $a = 1;),
                                q(our $b = 2;),
                                q($a = $a && $b;),
                                q($b = $b && $a)),
        log_or => join("\n",    q(my $a = 2;),
                                q(our $b = 1;),
                                q($a = $a || $b;),
                                q($b = $b || $a)),
        log_xor => no_warnings('void'),
                   join("\n",   q(my $a = 1;),
                                q(our $b = 2;),
                                q($a = $a xor $b;),
                                q($b = $b xor $a)),
        assignment_ops => join("\n",    q(my $a = 1;),
                                        q(our $b = 2;),
                                        q($a += $b + 1;),
                                        q($b -= $b - 1;),
                                        q($a *= $b + 1;),
                                        q($a /= $b - 1;),
                                        q($a .= $b . 'hello';),
                                        q($a **= $b + 1;),
                                        q($a &= $b;),
                                        q($a &&= $b;),
                                        q($b ||= $a;),
                                        q($b |= 1;),
                                        q($a ^= $b;),
                                        q($a <<= $b;),
                                        q($b >>= $a)),
        conditional_op => join("\n",    q(my($a, $b);),
                                        q($a = $b ? $a : 1)),
        flip_flop => join("\n",     q(my($a, $b);),
                                    q($a = $a .. $b;),
                                    q($a = $a ... $b)),
        references => join("\n",    q(my($scalar, @list, %hash);),
                                    q(my $a = \$scalar;),
                                    q($a = \\@list;),
                                    q($a = \\(@list, 1, 2);),
                                    q($a = \\%hash;),
                                    q($a = \\*scalar_assignment;),
                                    q($a = \\&scalar_assignment;),
                                    q($a = sub { my $inner = 1 };),
                                    q($a = sub {),
                                   qq(\tfirst_thing();),
                                   qq(\tsecond_thing()),
                                    q(})),
    );
};

subtest 'program flow' => sub {
    _run_tests(
        caller_fcn => join("\n",    q(my @info = caller();),
                                    q(my $package = caller();),
                                    q(@info = caller(1);),
                                    q($package = caller(2))),
        exit_fcn => join("\n",      q(exit(123);),
                                    q(exit($a);),
                                    q(exit())),
        do_file =>  join("\n",      q(my $val = do 'some_file.pl';),  # like require
                                    q($val = do $val)),
        do_block => join("\n",      q[my $val = do { sub_name() };],
                                    q[$val = do {],
                                   qq[\tfirst_thing();],
                                   qq[\tsecond_thing(1);],
                                   qq[\tthird_thing(1, 2, 3)],
                                    q[};],
                                    q[print 'done']),
        package_declaration => join("\n",   q(my $a = 1;),
                                            q(package Foo;),
                                            q(my $b = 2;),
                                            q(package Bar;),
                                            q(my $c = 3)),
        require_file => join("\n",      q(require 'file.pl';),
                                        q(my $file;),
                                        q(require $file)),
        require_module =>   q(require Some::Module),
        require_version =>  q(require v5.8.7),
        wantarray_keyword =>            q(my $wa = wantarray),
        return_keyword =>               q(return(1, 2, 3)),
        dump_keyword => no_warnings('misc'),
                        join("\n",      q(dump;),
                                        q(dump DUMP_LABEL)),
        goto_label => join("\n",        q(LABEL:),
                                        q(goto LABEL;),
                                        q(my $expr;),
                                        q(goto $expr)),
        goto_sub => join("\n",      q(goto &Some::sub;),
                                    q(goto sub { 1 })),
        if_statement => join("\n",  q(my $a;),
                                    q(if ($a) {),
                                   qq(\tprint 'hi'),
                                    q(}),
                                    q(if ($a) {),
                                   qq(\tprint 'hello';),
                                   qq(\tworld()),
                                    q(}),
                                    q(print 'done')),
        if_else => join("\n",       q(my $a;),
                                    q(if ($a) {),
                                   qq(\tprint 'hi'),
                                    q(} else {),
                                   qq(\tprint 'hello';),
                                   qq(\tworld()),
                                    q(}),
                                    q(print 'done')),
        elsif_else_chain => join("\n",  q(my $a;),
                                        q(if ($a < 1) {),
                                       qq(\tprint 'less'),
                                        q(} elsif ($a > 1) {),
                                       qq(\tprint 'more'),
                                        q(} elsif (defined($a)) {),
                                           qq(\tprint 'zero'),
                                        q(} else {),
                                       qq(\tprint 'undef'),
                                        q(}),
                                        q(print 'done')),
        elsif_chain => join("\n",   q(my $a;),
                                    q(if ($a < 1) {),
                                   qq(\tprint 'less'),
                                    q(} elsif ($a > 1) {),
                                   qq(\tprint 'more'),
                                    q(} elsif (defined($a)) {),
                                       qq(\tprint 'zero'),
                                    q(}),
                                    q(print 'done')),
        unless_statement => join("\n",  q(my $a;),
                                        q(unless ($a) {),
                                       qq(\tprint 'hi'),
                                        q(})),
        postfix_if => join("\n",    q(my $a;),
                                    q(print 'hi' if $a;),
                                    q(print 'done')),
        postfix_unless => join("\n",q(my $a;),
                                    q(print 'hi' unless $a;),
                                    q(print 'done')),
        while_loop => join("\n",    q(my($a, $b);),
                                    q(while ($a && $b) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(}),
                                    q(while ($a) {),
                                   qq(\tprint 'hi'),
                                    q(})),
        while_continue => join("\n",q(my $a;),
                                    q(while ($a) {),
                                   qq(\tprint 'hi'),
                                    q(} continue {),
                                   qq(\tprint 'continued';),
                                   qq(\tprint 'here'),
                                    q(}),
                                    q(print 'done')),
        until_loop => join("\n",    q(my $a;),
                                    q(until ($a && $b) {),
                                   qq(\tprint 'hi'),
                                    q(}),
                                    q(print 'done')),
        postfix_while => join("\n", q(my $a;),
                                    q(++$a while ($a < 5);),
                                    q(print 'hi' while ($a < 5);),
                                    q(do {),
                                   qq(\t++\$a;),
                                   qq(\tprint 'hi'),
                                    q(} while ($a < 5);),
                                    q(print 'done')),
        postfix_until => join("\n", q(my $a;),
                                    q(++$a until ($a < 5);),
                                    q(print 'hi' until ($a < 5);),
                                    q(do {),
                                   qq(\t++\$a;),
                                   qq(\tprint 'hi'),
                                    q(} until ($a < 5);),
                                    q(print 'done')),
        for_loop => join("\n",      q(for (my $a = 0; $a < 10; ++$a) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(}),
                                    q(print 'done')),
        foreach_loop => join("\n",  q(my @a;),
                                    q(foreach my $a (1, 2, @a) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(}),
                                    q(foreach our $a (@a) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(}),
                                    q(foreach my $a (reverse(@a)) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(})),
        foreach_range => join("\n", q(foreach my $a (1 .. 10) {),
                                   qq(\tprint 'hi';),
                                   qq(\tprint 'there'),
                                    q(}),
                                    q(print 'done')),
        postfix_foreach => join("\n",   q(my @a;),
                                        q(print() foreach (@a);),
                                        q(print 'done')),
        next_last_redo => join("\n",q(THE_LABEL:),
                                    q(foreach $_ (1, 2, 3) {),
                                   qq(\tnext;),
                                   qq(\tlast THE_LABEL;),
                                   qq(\tredo),
                                    q(})),
    );
};

#subtest 'misc stuff' => sub {
#    _run_tests(
#        # lock prototype reset
#    );
#};

subtest process => sub {
    _run_tests(
        alarm_fcn => q(alarm(4)),
        exec_fcn => no_warnings('exec'),
                    join("\n",  q(my $rv = exec('/bin/echo', 'hi', 'there');),
                                q($rv = exec('/bin/echo | cat');),
                                q($rv = exec { '/bin/echo' } ('hi', 'there');),
                                q(my $a = exec $rv ('hi', 'there'))),
        system_fcn => join("\n",q(my $rv = system('/bin/echo', 'hi', 'there');),
                                q($rv = system('/bin/echo | cat');),
                                q($rv = system { '/bin/echo' } ('hi', 'there');),
                                q(my $a = system $rv ('hi', 'there'))),
        fork_fcn => join("\n",  q(fork();),
                                q(my $a = fork())),
        getpgrp_fcn => join("\n",   q(my $a = getpgrp(0);),
                                    q($a = getpgrp(1234))),
        getppid_fcn => join("\n",   q(my $a = getppid();),
                                    q(getppid())),
        kill_fcn => join("\n",  q(my $rv = kill(0);),
                                q($rv = kill('HUP', $$);),
                                q($rv = kill(-9, 1, 2, 3);),
                                q($rv = kill('TERM', -1, -2, -3))),
        pipe_fcn => join("\n",  q(my($a, $b);),
                                q(pipe($a, $b))),
        readpipe_fcn => join("\n",  q(my $rv = `/bin/echo 'hi','there'`;),
                                    q($rv = `$rv`;),
                                    q($rv = readpipe('/bin/echo "hi","there"');),
                                    q($rv = readpipe($rv);),
                                    q($rv = readpipe(foo()))),
        sleep_fcn => join("\n",     q(my $a = sleep();),
                                    q($a = sleep(10))),
        times_fcn => join("\n",     q(my @a = times();),
                                    q(my $a = times())),
        wait_fcn => join("\n",      q(my $a = wait();),
                                    q(wait())),
        getpriority_fcn => join("\n",   q(my $a = getpriority(1, 2);),
                                        q($a = getpriority(0, 0))),
        setpriority_fcn => join("\n",   q($a = setpriority(1, 2, 3);),
                                        q($a = setpriority(0, 0, -2))),
        setpgrp_fcn => join("\n",   q(my $a = setpgrp();),
                                    q($a = setpgrp(0, 0);),
                                    q($a = setpgrp(9, 10))),
    );
};

subtest 'process waitpid' => sub {
    plan skip_all => q(WNOHANG isn't defined on Windows) if $^O eq 'MSWin32';
    _run_tests(
        waitpid_fcn => join("\n",   q(my $a = waitpid(123, WNOHANG | WUNTRACED);),
                                    q($a = waitpid($a, 0))),
    );
};

subtest classes => sub {
    _run_tests(
        bless_fcn => join("\n", q(my $obj = bless({}, 'Some::Package');),
                                q($obj = bless([]))),
        ref_fcn => join("\n",   q(my $r = ref(1);),
                                q($r = ref($r);),
                                q($r = ref())),
        tie_fcn => join("\n",   q(my $a;),
                                q(my $r = tie($a, 'Some::Package', 1, 2, 3);),
                                q($r = tie($r, 'Other::Package', $a))),
        tied_fcn => join("\n",  q(my $a;),
                                q(my $r = tied($a))),
        untie_fcn => join("\n", q(my $a;),
                                q(untie($a))),
    );
};

subtest sockets => sub {
    _run_tests(
        accept_fcn => join("\n",q(my($a, $b);),
                                q(my $rv = accept($a, $b))),
        bind_fcn => join("\n",  q(my($sock, $name);),
                                q(my $rv = bind($sock, $name))),
        connect_fcn => join("\n",   q(my($sock, $name);),
                                    q(my $rv = connect($sock, $name))),
        listen_fcn => join("\n",    q(my $sock;),
                                    q(my $rv = listen($sock, 5))),
        getpeername_fcn => join("\n",   q(my $sock;),
                                        q(my $rv = getpeername($sock))),
        getsockname_fcn => join("\n",   q(my $sock;),
                                        q(my $rv = getsockname($sock))),
        getsockopt_fcn => join("\n",    q(my $sock;),
                                        q(my $rv = getsockopt($sock, 1, 2))),
        setsockopt_fcn => join("\n",    q(my $sock;),
                                        q(my $rv = setsockopt($sock, 1, 2, 3))),
        send_fcn => join("\n",  q(my($sock, $dest);),
                                q(my $rv = send($sock, 'themessage', 1);),
                                q($rv = send($sock, $rv, 1, $dest))),
        recv_fcn => join("\n",  q(my($sock, $buf);),
                                q(my $rv = recv($sock, $buf, 123, 456))),
        shutdown_fcn => join("\n",  q(my $sock;),
                                    q(my $rv = shutdown($sock, 2))),
        socket_fcn => join("\n",    q(my $sock;),
                                    q(my $rv = socket(SOCK, PF_INET, SOCK_STREAM, 3);),
                                    q($rv = socket(*SOCK, PF_UNIX, SOCK_DGRAM, 2);),
                                    q($rv = socket($sock, PF_INET, SOCK_RAW, 1))),
        socketpair_fcn => join("\n",q(my($a, $b);),
                                    q(my $rv = socketpair(SOCK, $a, AF_UNIX, SOCK_STREAM, PF_UNSPEC);),
                                    q($rv = socketpair($b, *SOCK, AF_INET6, SOCK_DGRAM, 1234))),
    );
};

subtest 'sysV ipc' => sub {
    _run_tests(
        msgctl_fcn => join("\n",    q(my $a;),
                                    q(my $rv = msgctl(1, 2, $a))),
        msgget_fcn => join("\n",    q(my $a;),
                                    q(my $rv = msgget($a, 0))),
        msgsnd_fcn => join("\n",    q(my $a;),
                                    q(my $rv = msgsnd(1, $a, 0))),
        msgrecv_fcn => join("\n",   q(my $a;),
                                    q(my $rv = msgrecv(1, $a, 1, 2, 3))),
        semctl_fcn => join("\n",    q(my $a;),
                                    q(my $rv = semctl(1, $a, 2, 3))),
        semget_fcn => join("\n",    q(my $a;),
                                    q(my $rv = semget(1, $a, 2))),
        semop_fcn => join("\n",     q(my $a;),
                                    q(my $rv = semop(1, $a))),
        shmctl_fcn => join("\n",    q(my $a;),
                                    q(my $rv = shmctl(1, $a, 2))),
        shmget_fcn => join("\n",    q(my $a;),
                                    q(my $rv = shmget(1, $a, 2))),
        shmread_fcn => join("\n",   q(my $a;),
                                    q(my $rv = shmread(1, $a, 2, 3))),
        shmwrite_fcn => join("\n",  q(my $a;),
                                    q(my $rv = shmwrite(1, $a, 2, 3))),
    );
};

subtest time => sub {
    _run_tests(
        localtime_fcn => join("\n", q(my $a = localtime();),
                                    q(my @a = localtime(12345))),
        gmtime_fcn => join("\n",    q(my $a = gmtime();),
                                    q(my @a = gmtime(12345))),
        time_fcn => join("\n",      q(my $a = time();),
                                    q(time())),
    );
};

subtest 'perl-5.10.1' => sub {
    _run_tests(
        requires_version(v5.10.1),
        unpack_one_arg => join("\n", q($a = unpack($a))),
        mkdir_no_args => join("\n",  q(mkdir())),
        say_fcn => join("\n",   q(my $a = say();),
                                q(say('foo bar', 'baz', "\n");),
                                q(say F ('foo bar', 'baz', "\n");),
                                q(say "Hello\n";),
                                q(say F "Hello\n";),
                                q(my $f;),
                                q(say { $f } ('foo bar', 'baz', "\n");),
                                q(say { *$f } ('foo bar', 'baz', "\n"))),
        stacked_file_tests =>   q(-r -x -d '/tmp'),
        defined_or => join("\n",q(my $a;),
                                q(my $rv = $a // 1;),
                                q($a //= 4)),
    );
};

subtest 'given-when-5.10.1' => sub {
    _run_tests(
        requires_version(v5.10.1),
        excludes_only_version(v5.27.7),
        given_when_5_10 => join("\n",
                                q(my $a;),
                                q(given ($a) {),
                               qq(\twhen (1) { print 'one' }),
                               qq(\twhen (2) {),
                               qq(\t\tprint 'two';),
                               qq(\t\tprint 'more';),
                               qq(\t\tcontinue),
                               qq(\t}),
                               qq(\twhen (3) {),
                               qq(\t\tprint 'three';),
                               qq(\t\tbreak;),
                               qq(\t\tprint 'will not run'),
                               qq(\t}),
                               qq(\tdefault { print 'something else' }),
                                q(})),
    );
};

# from the reverted given/whereso/whereis from 5.27.7
#subtest 'given-when-5.27.7' => sub {
#    _run_tests(
#        requires_version(v5.27.7),
#        given_when_5_27 => join("\n",
#                              q(my $a;),
#                              q(given ($a) {),
#                             qq(\twhereso (m/abc/) {),
#                             qq(\t\tprint 'abc';),
#                             qq(\t\tprint 'ABC'),
#                             qq(\t}),
#                             qq(\twhereso (m/def/) {),
#                             qq(\t\tprint 'def'),
#                             qq(\t}),
#                             qq(\tprint 'ghi' whereso (m/ghi/);),
#                             qq(\twhereis ('123') {),
#                             qq(\t\tprint '123'),
#                             qq(\t}),
#                             qq(\tprint '456' whereis (456);),
#                             qq(\tprint 'default case'),
#                             qq(})),
#    );
#};

subtest 'perl-5.12' => sub {
    _run_tests(
        requires_version(v5.12.0),
        keys_array => join("\n",    q(my @a = (1, 2, 3, 4);),
                                    q(keys(@a))),
        values_array => join("\n",  q(my @a = (1, 2, 3, 4);),
                                    q(values(@a))),
        each_array => join("\n",    q(my @a = (1, 2, 3, 4);),
                                    q(each(@a))),
    );
};

subtest 'perl-5.14' => sub {
    _run_tests(
        requires_version(v5.14.0),
        tr_r_flag => no_warnings('misc'),
                     join("\n",     q(my $a;),
                                    q($a = tr/$a/zyxw/cdsr)),
    );
};

subtest '5.14 experimental ref ops' => sub {
    _run_tests(
        requires_version(v5.14.0),
        excludes_version(v5.24.0),
        no_warnings(),
        keys_ref => join("\n",  q(my $h = {1 => 2, 3 => 4};),
                                q(keys($h);),
                                q(my $a = [1, 2, 3];),
                                q(keys($a))),
        each_ref => join("\n",  q(my $h = {1 => 2, 3 => 4};),
                                q(my $v = each($h);),
                                q(my $a = [1, 2, 3];),
                                q(each($a))),
        values_ref => join("\n",q(my $h = {1 => 2, 3 => 4};),
                                q(values($h);),
                                q(my $a = [1, 2, 3];),
                                q(values($a))),
        pop_ref => join("\n",   q(my $a = [1, 2, 3];),
                                q(pop($a))),
        push_ref => join("\n",  q(my $a = [1, 2, 3];),
                                q(push($a, 1))),
        shift_ref => join("\n", q(my $a = [1, 2, 3];),
                                q(shift($a))),
        unshift_ref => join("\n",   q(my $a = [1, 2, 3];),
                                    q(unshift($a, 1))),
        splice_ref => join("\n",    q(my $a = [1, 2, 3];),
                                    q(splice($a, 2, 3, 4))),
    );
};

subtest 'perl-5.18' => sub {
    _run_tests(
        requires_version(v5.18.0),
        dump_expr => no_warnings('misc'),
                     join("\n", q(my $expr;),
                                q(dump $expr;),
                                q(dump 'foo' . $expr)),
        next_last_redo_expr => join("\n",   q(foreach my $a (1, 2) {),
                                           qq(\tnext \$a;),
                                           qq(\tlast 'foo' . \$a;),
                                           qq(\tredo \$a + \$a),
                                            q(})),
    );
};

subtest 'perl-5.20 incompatibilities' => sub {
    _run_tests(
        excludes_version(v5.20.0),
        do_sub =>   q(my $val = do some_sub_name(1, 2)), # deprecated sub call
    );
};

subtest 'perl-5.20' => sub {
    _run_tests(
        requires_version(v5.20.0),
        hash_slice_hash => join("\n",   q(my(%h, $h);),
                                        q(my %slice = %h{'key1', 'key2'};),
                                        q(%slice = %$h{'key1', 'key2'})),
        hash_slice_array=> join("\n",   q(my(@a, $a);),
                                        q(my %slice = %a[1, 2];),
                                        q(%slice = %$a[1, 2])),
        # although there's no way to distinguish @$a from $a->@*, it checks whether
        # the "postderef" feature is on and uses it if it is
        # commented out for now because it messed with the two slice tests above
#        postderef => join("\n",         q(my $a = 1;),
#                                        q(our $b = 2;),
#                                        q($a->[1]->$*;),
#                                        q($a->{'one'}->@*;),
#                                        q($b->[1]->$#*;),
#                                        q($b->{'one'}->%*;),
#                                        q($a->[1]->&*;),
#                                        q($a->[1]->**;)),
# postfix dereferencing
# $a->@*
# $a->@[1,2]
# $a->%{'one', 'two'}
# check warning bits for "use experimental 'postderef'
    );
};

subtest 'perl-5.22 differences' => sub {
    _run_tests(
        excludes_version(v5.22.0),
        readline_with_brackets => join("\n",    q(my $fh;),
                                                q(my $line = <$fh>;),
                                                q(my @lines = <$fh>)),
        hash_key_assignment => join("\n",   q(my(%a, $a);),
                                            q($a{key} = 1;),
                                            q($a{'key'} = 1;),
                                            q($a{'1'} = 1;),
                                            q($a->{key} = 1;),
                                            q($a->{'key'} = 1;),
                                            q($a->{'1'} = 1)),
    );
};

subtest 'perl-5.22' => sub {
    _run_tests(
        requires_version(v5.22.0),
        use_feature('bitwise'),
        use_feature('refaliasing'),
        string_bitwise  => join("\n",   q(my($a, $b);),
                                        q($a = $a &. $b;),
                                        q($a &.= $b;),
                                        q($a = $a |. 'str';),
                                        q($a |.= 'str';),
                                        q($a = $a ^. 1;),
                                        q($a ^.= $b;),
                                        q($a = ~.$a)),
        regex_n_flag => join("\n",  q(my $str;),
                                    q($str =~ m/(hi|hello)/n)),
        list_repeat => join("\n",   q(my @a = (1, 2) x 5)),
        ref_alias => join("\n",     q(my($a, $b) = (1, 2);),
                                    q(\$a = \$b;),
                                    q[\($a) = \$b;],
                                    q(our @array = (1, 2);),
                                    q(\$array[1] = \$a;),
                                    q(my %hash = (1, 1);),
                                    q(\$hash{'1'} = \$b)),
        listref_alias => join("\n", q(my($a, $b, @array);),
                                    q(\@array[1, 2] = (\$a, \$b);),
                                    q[\(@array) = (\$a, \$b)]),
        alias_whole_array => join("\n", q(my @array = (1, 2);),
                                        q(our @ar2 = (1, 2);),
                                        q[\(@array) = \(@ar2);],
                                        q[\(@ar2) = \(@array)]),
        double_diamond => join("\n",    q(while (defined($_ = <<>>)) {),
                                       qq(\tprint()),
                                        q(})),
    );
};

subtest 'perl-5.25.6 split changes' => sub {
    _run_tests(
        excludes_version(v5.25.6),
        split_specials => join("\n",    q(our @s = split('', $a);),
                                        q(my @strings = split(' ', $a))),
    );
};

sub requires_version {
    my $ver = shift;
    Devel::Chitin::RequireVersion->new($ver);
}

sub use_feature {
    my $f = shift;
    Devel::Chitin::UseFeature->new($f);
}

sub excludes_version {
    my $ver = shift;
    Devel::Chitin::ExcludeVersion->new($ver);
}

sub excludes_only_version {
    my $ver = shift;
    Devel::Chitin::ExcludeOnlyVersion->new($ver);
}

sub no_warnings {
    my $warn = shift;
    Devel::Chitin::NoWarnings->new($warn);
}

sub _run_tests {
    my @tests = @_;

    my $testwide_preamble = '';
    while (@tests and blessed($tests[0])) {
        my $obj = shift @tests;
        my $directive = $obj->compose();
        if (defined $directive) {
            $testwide_preamble .= $directive;
        } else {
            return ();
        }
    }

    plan tests => _count_tests(@tests);

    while (@tests) {
        my $test_name = shift @tests;

        my $preamble = '';
        while (blessed $tests[0]) {
            $preamble .= shift(@tests)->compose;
        }
        my $code = shift @tests;
        my $eval_string = "${testwide_preamble}${preamble}sub $test_name { $code }";
        my $exception = do {
            local $@;
            eval $eval_string;
            $@;
        };
        if ($exception) {
            die "Couldn't compile code for $test_name: $exception\nCode was:\n$eval_string";
        }
        (my $expected = $code) =~ s/\b(?:my|our)\b\s*//mg;
        my $ops = _get_optree_for_sub_named($test_name);
        my $got = eval { $ops->deparse };
        is($got, $expected, "code for $test_name")
            || do {
                diag("showing whitespace:\n>>".join("<<\n>>", split("\n", $got))."<<");
                diag("\$\@: $@\nTree:\n");
                $ops->print_as_tree
            };
    }
}

sub _count_tests {
    my @tests = @_;
    my $count = 0;
    for (my $i = 0; $i < @tests; $i++) {
        next if ref($tests[$i]);
        $count++;
    }
    return int($count / 2);
}

sub _get_optree_for_sub_named {
    my $subname = shift;
    Devel::Chitin::OpTree->build_from_location(
        Devel::Chitin::Location->new(
            package => 'main',
            subroutine => $subname,
            filename => __FILE__,
            line => 1,
        )
    );
}

package Devel::Chitin::TestDirective;
sub new {
    my($class, $code) = @_;
    return bless \$code, $class;
}

package Devel::Chitin::RequireVersion;
use base 'Devel::Chitin::TestDirective';
use Test::More;

sub compose {
    my $self = shift;
    my $required_version_string = sprintf('%vd', $$self);
    if ($^V lt $$self) {
        plan skip_all => "needs version $required_version_string";
        return undef;
    }

    my $preamble = "use $required_version_string;";
    if ($^V ge v5.18.0) {
        $preamble .= "\nno warnings 'experimental';";
    }
    return $preamble;
}

package Devel::Chitin::ExcludeVersion;
use base 'Devel::Chitin::TestDirective';
use Test::More;

sub compose {
    my $self = shift;
    my $excluded_version_string = sprintf('%vd', $$self);
    if ($^V ge $$self) {
        plan skip_all => "doesn't work starting with version $excluded_version_string";
        return undef;
    }
    return '';
}

package Devel::Chitin::ExcludeOnlyVersion;
use base 'Devel::Chitin::TestDirective';
use Test::More;

sub compose {
    my $self = shift;
    my $excluded_version_string = sprintf('%vd', $$self);
    if ($^V eq $$self) {
        plan skip_all => "doesn't work with version $excluded_version_string";
        return undef;
    }
    return '';
}

package Devel::Chitin::UseFeature;
use base 'Devel::Chitin::TestDirective';
sub compose {
    my $self = shift;
    sprintf(q(use feature '%s';), $$self);
}

package Devel::Chitin::NoWarnings;
use base 'Devel::Chitin::TestDirective';
sub compose {
    my $self = shift;
    $$self ? sprintf(q(no warnings '%s';), $$self) : 'no warnings;';
}
