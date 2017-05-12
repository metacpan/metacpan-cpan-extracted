package Devel::WxProf::Reader::DProf;
use strict; use warnings;
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
    my @name_from = ();
    my @root_from = ();

    my ($package_name, $function_name);

    my $header = 1;
    my $elapsed = 0;

    my $line = <$fh>;
    if ($line !~m{ \A #ForTyTwo }xms) {
        die "File does not look like a perl profile";
    }

    while ($line = <$fh>) {
        if ($header) {
            # print $line;
            $line =~m{^PART2}xms
                or next;
            $header--;
        }
        # print $line;
        chomp $line;
        my @field_from = split m{\s}x , $line;

        if ($field_from[0] eq '+') {
            # skip old-style lines
            next if ($field_from[1] eq '&');
            # enter
            my $start = $elapsed;
            # print "Enter at $start - ", join("::", @{ $name_from[hex $field_from[1] ] }), "\n";

            ($package_name, $function_name) = @{ $name_from[hex $field_from[1] ] };
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
                start => $elapsed,
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

            # leave
            my $end = $elapsed;
            # print "End at $end - ", join(" ::", @{ $name_from[hex $field_from[1] ] }), "\n";
                        # skip old-style lines
            ($package_name, $function_name) = @{ $name_from[ hex $field_from[1] ] };

            pop @sub_from;

            # remove overhead
            $current->set_end($elapsed);

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
        elsif ($field_from[0] eq '@') {
            # time
            # print $line,"\n";
            my @time_from = split m{\s}x, $line;
            $elapsed += $time_from[3];

        }
        elsif ($field_from[0] eq '&') {
            # register
            # list ref for efficiency
            # warn "$field_from[2]::$field_from[3]";
            $name_from[hex $field_from[1] ] = [ $field_from[2], $field_from[3] ];
        }
    }
    return @root_from;
}

if (! caller()) {
    my $reader = __PACKAGE__->new();
    print $reader->read_file('../../../../../SOAP-WSDL/benchmark/tmon.out');
    print "\n";
    use Data::Dumper;
    print Data::Dumper::Dumper $reader->get_packages;


}



1;