package Devel::WxProf::Reader::WxProf;
use strict; #use warnings;
use Class::Std::Fast;
use IO::File;

use Devel::WxProf::Data;

my %packages_of :ATTR(:get<packages>        :default<{}>);
my %data_of     :ATTR(:get<data>            :default<()>);

sub read_file {
    my ($self, $file) = @_;
    my $fh = IO::File->new($file, O_RDONLY)
        or die "cannot read $file";

    my $current = undef;
    my @sub_from = (undef);
    my @root_from = ();
    my $header = 1;

    my $overhead;

    my $line = <$fh>;
    chomp $line;
    if ($line !~m{ \A #WxProfile }xm) {
        die "File does not look like a WxProfile file";
    }

    while ($line = <$fh>) {
        if ($header) {
            if ($line =~m{^overhead=(\d+)}x) {
                $overhead = $1;
            };
            $line =~m{^PART2}xms
                or next;
            $header--;
        }

        chomp $line;
        my @field_from = split m{\s}x , $line;
        if ($field_from[0] eq '+') {
            # skip old-style lines
            next if ($field_from[1] eq '&');
            # enter
            next if $field_from[2] =~s{<anon>}{__ANON__:};
            my ($package_name, $function_name) = $field_from[2] =~ m{^(.+)::([^:]+)$}x;
            if (not exists $packages_of{ $$self }->{ $package_name }) {
                $packages_of{ $$self }->{ $package_name } = Devel::WxProf::Data->new({
                    package => $package_name,
                    start => 0,
                    end => 0,
                });
            }
            my $package_function_of_ref = $packages_of{ $$self }->{ $package_name }->get_function() || {};
            if (not exists $package_function_of_ref->{ $function_name }) {
                $package_function_of_ref->{ $function_name } = Devel::WxProf::Data->new({
                    package => $package_name,
                    start => 0,
                    end => 0,
                    function => $function_name,
                });
                $packages_of{ $$self }->{ $package_name }->set_function($package_function_of_ref)
            }


            my $new_sub = Devel::WxProf::Data->new({
                start => $field_from[1],
                package => $package_name,
                function => $function_name,
                calls    => 1,
            });
            push @sub_from, $new_sub;
            $current->add_child_node( $new_sub )
                if defined($current);
            $current = $new_sub;
        }
        elsif ($field_from[0] eq '-') {
            # skip old-style lines
            next if ($field_from[1] eq '&');
            next if $field_from[2] =~s{<anon>}{__ANON__:};
            # leave
            pop @sub_from;

            my ($package_name, $function_name) = $field_from[2] =~ m{^(.+)::([^:]+)$}x;

            # remove overhead
            $current->set_end($field_from[1] - $overhead);
            my $elapsed = $current->get_elapsed();
            # add elapsed time to package total time (start is 0, so end is total)
            $packages_of{ $$self }->{ $package_name }->add_end( $elapsed );
            # add elapsed time to function total time (start is 0, so end is total)
            $packages_of{ $$self }->{ $package_name }->get_function()->{ $function_name}
                ->add_end( $elapsed );
            # add single call to overview
            $packages_of{ $$self }->{ $package_name }->get_function()->{ $function_name}
                ->add_child_node( $current );

            if (not defined $sub_from[-1]) {
                push @root_from, $current;
                undef $current;
            }
            $current = $sub_from[-1];
        }
        elsif ($field_from[0] eq '@') {return
            # time
            print $line,"\n";
        }
        elsif ($field_from[0] eq '&') {
            # register
            # list ref for efficiency
            $sub_from[hex $field_from[1] ] = [ $field_from[2], $field_from[3] ];
        }
    }
    $fh->close();
    $data_of{ $$self } = [ @root_from ];    # make a copy
    return @root_from;
}

sub print_tree {
    my @result = @{ $_[0] };
    my $max_depth = $_[1];
    my $ignore = $_[2];#  || {};
    my $ignore_function = $_[3];
    my $indent = q{ };
    my $depth = 0;

    while (1) {
        my $node = shift @result;
        if (not defined $node) {
            $depth--;
            last if not @result;
            next;
        }
        if (exists $ignore_function->{ $node->get_function }) {
            next;
        }
        print $indent x $depth, $node->get_elapsed, q{ }, $node->get_package, q{::}, $node->get_function(), "\n";

        if ($depth < $max_depth) {
            my $children_from = $node->get_child_nodes;
            if (@{ $children_from }) {
                $depth++;
                @result = (@{ $children_from }, undef, @result);
            }
        }
        last if not @result;
    }
}

if (! caller()) {
    my $reader = __PACKAGE__->new();
    my @result = $reader->read_file('../../../../SOAP-WSDL/benchmark/tmon.out');
    # print map { defined $_ ? $_->_DUMP : () } @result;
    print scalar @result, "\n";
    print_tree( [ @result ], 3, { }, { 'DESTROY' => 1});
}

1;