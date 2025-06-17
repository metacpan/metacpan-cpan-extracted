package Mhouse::Reports;
=pod
    # PROGRAM: Mhouse_Reports.pm
    # PURPOSE: Use mhouse business data for scoring and reporting.
    # DATE CREATED: 2025 07 16
    # PARAMETERS: 
    # USAGE:
        my @folder_list = qw(sg ti);
        my @scored_field_list = qw(e_data communication tourism_sector industry_1 industry_2);
        my @cumulative_llm_answers = Mhouse_Reports::read_mhouse_scored_data(\@folder_list, \@scored_field_list);

        printf "Total selected before grep: %d\n", scalar @cumulative_llm_answers;

        my @sorted_arr = sort {
            $b->{e_data} <=> $a->{e_data} || $b->{communication} <=> $a->{communication}
        } grep {
            $_->{company_employee_count_range} =~ /^(1-3)$/ && (scalar $_->{e_data} > 0.8 || scalar $_->{communication} > 0.8 )
        }@cumulative_llm_answers;

        my $annotation_hashref = Mhouse_Reports::read_mhouse_annotations_from_folder("./RESULTS");
        print Dumper $annotation_hashref ;
        my $displayed_field_arrref = [qw(energy_sector automation e_data programming)];
        Mhouse_Reports::output_llm_scored_mhouse_json_annotated(\@sorted_arr, "./displayed_list_8.html", $annotation_hashref, $displayed_field_arrref);
=cut

# binmode(STDOUT, ":utf8");
use File::Path qw(make_path);
use File::Find;
use Cwd 'cwd';
use File::Spec;
use JSON;
our $VERSION = '0.01';

sub get_array_from_authenticated_json_file{
    my $input_data_fn = shift;
    open(my $input_data_fh, '<', $input_data_fn) or die $!;
    my $document = do { local $/ = undef; <$input_data_fh> };
    my $parsed_json = decode_json($document);
    my @arr_to_iterate = @{$parsed_json};
    my $arr_size = @arr_to_iterate;
    print "\@arr_to_iterate size=$arr_size\n";
    return @arr_to_iterate;
}

sub read_mhouse_llm_scored_data{
	my ($subfolder_list_ref, $scored_field_ref) = @_;
    my @cumulative_llm_answers = ();
	for my $root_dir (@{$subfolder_list_ref}){
        my @llm_answers;
		traverse_folder_tree_jsontxt(sub{push @llm_answers, get_array_from_authenticated_json_file(shift);}, $root_dir);
		printf "%s: total recs = %d\n", $root_dir, scalar @llm_answers;
        push @cumulative_llm_answers, @llm_answers;
	};
	
	foreach my $rec (@cumulative_llm_answers){
		my ($llm_answer_json_part) = ($rec->{llm_answer} =~ /(\{.*\})/s);
        $rec->{company_employee_count_range} = $rec->{employees};
		
		$llm_answer_json_part =~ s/\R/ /g;
		my $data;
		eval{$data = decode_json($llm_answer_json_part);};
		if($@){
			print "Exception in decode_json\n";
			next;
		}
        foreach my $kw (@{$scored_field_ref}){
            $rec->{$kw} = $data->{$kw};
        }
	}
	return @cumulative_llm_answers;
}


=pod
FUNCTION: read_mhouse_annotations
USAGE:
    my $return_href = read_mhouse_annotations("./RESULTS/20250520_1300_bl_1_3.txt");
    print Dumper $return_href ;
=cut

sub read_mhouse_annotations{
	my $anno_fn = shift;
	my %hash_out;
	open my $anno_fh, "<", $anno_fn or die $!;
	binmode($anno_fh, ":utf8");	
	
	while(<$anno_fh>){
		my ($legal_name, $annotation) = (/Google\s*(\S.*\S)\s*->\s*(.*)$/) or next;
        next if $annotation =~ /^\s*$/;
		$hash_out{$legal_name} = $annotation;
	}
	return \%hash_out;
}

sub read_mhouse_annotations_from_folder{
    my $dirname = shift;

    opendir(D, "$dirname") || die "Can't open directory $dirname: $!\n";
    my @file_list = readdir(D);
    my %cumul_hash;
    foreach my $entry (@file_list) {
        next if $entry =~ /^\.{1,2}$/;
        next unless $entry =~ /\.txt$/;

        printf "%s\n", $entry;
        open(my $fh, "<", "$dirname/$entry") or die $!;
        my $href = read_mhouse_annotations("$dirname/$entry");
        %cumul_hash = (%cumul_hash, %$href);
    }
    return \%cumul_hash;
}

sub output_llm_scored_mhouse_json_annotated{
    my $arref        = shift;
    my $out_fn       = shift;
    my $anno_hashref = shift;
    my $displayed_field_arrref = shift;
    my @cumulative_llm_answers = @{$arref};
    open my $outfh, ">", $out_fn or die $!;
    binmode($outfh, ":utf8");
    printf $outfh "<pre>";

    printf "%d records total\n", $#cumulative_llm_answers + 1;
    my $counter = 0;
    foreach my $company_data(@cumulative_llm_answers){
        printf $outfh "%5d   ", $counter++;
        foreach my $field (@{$displayed_field_arrref}){
            printf $outfh "%5s ", $company_data->{$field};
        }
        printf $outfh "%10s : %40s : ", $company_data->{company_employee_count_range}, do { my $s = $company_data->{address_composed_string}; chomp $s; $s };
        my $legalName = $company_data->{legalName};
        my $legalName_plus = $legalName =~ s/\s/+/gr;
        my $address_composed_string_plus = $company_data->{address_composed_string} =~ s/\s/+/gr;
        my $hyperlink_google = sprintf "<a href='https://www.google.com/search?q=+" . $legalName_plus . "+" . $address_composed_string_plus . "' target='_blank'>Google</a>";
        my $hyperlink_ducky  = sprintf "<a href='https://duckduckgo.com/?q=!ducky+%s+%s' target='_blank'>%-30s</a>", $legalName_plus, $address_composed_string_plus, $legalName;
        printf $outfh "%-10s    %s  -> %s <br>", $hyperlink_google, $hyperlink_ducky, $anno_hashref->{$legalName};
    }
    close $outfh;
}

=pod
    FUNCTION: traverse_folder_tree_jsontxt
    USAGE:
        my @cumulative_llm_answers = ();
        traverse(sub{push @cumulative_llm_answers, get_array_from_authenticated_json_file(shift);}, '../zh');
        printf "Total company count = %d\n", scalar @cumulative_llm_answers;
=cut

sub traverse_folder_tree_jsontxt{
    my ($callback, $root_dir) = @_;
    my $cwd = cwd();
    find(
        sub {
            return unless -f $_;
            return unless $_ =~ /\.json\.txt$/;
            my $fn = $File::Find::name;
            my $full = File::Spec->rel2abs($fn, $cwd);
            $callback->($full);
        },
        $root_dir
    );
}

1;
