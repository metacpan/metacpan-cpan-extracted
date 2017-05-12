
use Kook::Util ('read_file', 'write_file');
use Cwd;

my $project   = prop('project', "Kook");
my $release   = prop('release', "0.0100");
my $copyright = "copyright(c) 2009-2011 kuwata-lab.com all rights reserved.";
my $license   = prop('license', "MIT License");

$kook->{default} = "test";

recipe "test", {
    method  => sub {
        sys("prove t/*.t");
    }
};

recipe 'package', {
    desc    => 'create package',
    ingreds => ['dist'],
    method  => sub {
        my $base = "$project-$release";
        my $dir = "dist/$base";
        cd $dir, sub {
            my $perl = $^X;
            sys "$perl Makefile.PL";
            sys 'make';
            #sys 'make disttest';
            sys 'make dist';
        };
        mv "$dir/$base.tar.gz", '.';
        rm_r "dist/$base";
        cd "dist", sub {
            sys "gzip -cd ../$base.tar.gz | tar xf -";
        };
    }
};

my @text_files = qw(MIT-LICENSE README Changes Kookbook.pl Makefile.PL);  # exclude 'MANIFEST'

recipe "dist", {
    ingreds => ['bin/kk', 'doc'],
    method  => sub {
        #
        my $dir = "dist/$project-$release";
        rm_rf $dir if -d $dir;
        mkdir_p $dir;
        #
        store @text_files, $dir;
        store 'lib/**/*', 't/**/*', 'bin/**/*', $dir;
        #store 'doc/users-guide.html', 'doc/docstyle.css', $dir;
        chmod 0755, glob("$dir/bin/*");
        #
        edit "$dir/**/*", sub {
            s/\$Release: 0.0100 $/\$Release: 0.0100 $release \$/g;
            s/\$Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $/\$Copyright: copyright(c) 2009-2011 kuwata-lab.com all rights reserved. $copyright \$/g;
            s/\$License: MIT License $/\$License: MIT License $license \$/g;
            s/\$Release\$/$release/g;
            s/\$Copyright\$/$copyright/g;
            s/\$License\$/$license/g;
            $_;
        };
        #
        cd $dir, sub {
            #rm 'MANIFEST';
            #sys 'perl "-MExtUtils::Manifest=mkmanifest" -e mkmanifest 2>/dev/null';
            #rm 'MANIFEST.bak' if -f 'MANIFEST.bak';
            open my $fh, '<', 'MANIFEST'; close($fh);
            sys "find . -type f | sed -e 's=^\\./==g' > MANIFEST";
            cp 'MANIFEST', '../..';
        };
        #
    }
};

my $orig_kk = "../python/bin/kk";

recipe "bin/kk", {
    ingreds => [$orig_kk],
    desc  => "copy from '$orig_kk'",
    method => sub {
        my ($c) = @_;
        cp($c->{ingred}, $c->{product});
    }
};


## for documents

recipe "doc", ['doc/users-guide.html', 'doc/docstyle.css'];

recipe "doc/users-guide.html", ['doc/users-guide.txt'], {
    byprods => ['users-guide.toc.html', 'users-guide.tmp'],
    method => sub {
        my ($c) = @_;
        my $tmp = $c->{byprods}->[1];
        sys "kwaser -t html-css -T $c->{ingred} > $c->{byprod}";
        sys "kwaser -t html-css    $c->{ingred} > $tmp";
        sys_f "tidy -q -i -wrap 9999 $tmp > $c->{product}";
        rm_f $c->{byprods};
    }
};

recipe "doc/users-guide.txt", ['../common/doc/users-guide.eruby'], {
    method => sub {
        my ($c) = @_;
        mkdir "doc" unless -d "doc";
        sys "erubis -E PercentLine -p '\\[% %\\]' $c->{ingred} > $c->{product}";
    }
};

recipe 'doc/docstyle.css', ['../common/doc/docstyle.css'], {
    method => sub {
        my ($c) = @_;
        mkdir "doc" unless -d "doc";
        cp $c->{ingred}, $c->{product};
    }
};
