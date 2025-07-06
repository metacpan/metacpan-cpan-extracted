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
use DateTime;
use strict;

our $VERSION = '0.05';

sub get_timestamp{
    my $local_time_zone = DateTime::TimeZone->new( name => 'local' );
    my $dt = DateTime->now(time_zone => $local_time_zone);
    my $timestamp = sprintf("%4d%02d%02d_%02d%02d_%02d", $dt->year, $dt->month, $dt->day, $dt->hour, $dt->minute, $dt->second );
    return $timestamp;
}

sub get_array_from_authenticated_json_file{
    my $input_data_fn = shift;
    open(my $input_data_fh, '<', $input_data_fn) or die $!;
    my $document = do { local $/ = undef; <$input_data_fh> };
    my $parsed_json = decode_json($document);
    my @arr_to_iterate = @{$parsed_json};
    my $arr_size = @arr_to_iterate;
    # print "\@arr_to_iterate size=$arr_size\n";
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
        my ($address_composed_string) = ($rec->{address_composed_string} =~ /(\{.*\})/s);
        $rec->{company_employee_count_range} = $rec->{employees};
		
		$llm_answer_json_part =~ s/\R/ /g;
		my $data;
		eval{$data = decode_json($llm_answer_json_part);};
		if($@){
            printf "Exception in decode_json : %s %s\n", $rec->{all_preexisting_data}->{address}->{addressRegion}, $rec->{legalName} ;
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

sub get_header{
	my $config_fn = shift;
	my $arrref_before = shift;
	my $arrref_after  = shift;
	open my $config_fh, "<", $config_fn or die "Cannot open $config_fn: $!";
	my $config_file_contents = do {local $/; <$config_fh>; };
	
	my $time = sprintf "\nTime generated  : %s \n", get_timestamp() ;
	
	my $freq_table = get_freq_table(@{$arrref_before});
	my $before_grep = sprintf "Total before grep : %d (%s)\n", scalar @{$arrref_before}, $freq_table;
	my $displayed = sprintf "Total displayed   : %d \n\n", scalar @{$arrref_after};
	my $header =
	$config_file_contents .
	$time .
	$before_grep .
	$displayed
	;
	return $header;
}


sub output_llm_scored_mhouse_json_annotated{
    my $arref        = shift;
    my $out_fn       = shift;
    my $anno_hashref = shift;
    my $displayed_field_arrref = shift;
	my $config_fn = shift;
	my $header = shift;
    my @cumulative_llm_answers = @{$arref};
    open my $outfh, ">", $out_fn or die $!;
    binmode($outfh, ":utf8");
    print $outfh "<pre>";
	
	open my $config_fh, "<", $config_fn or die "Cannot open $config_fn: $!";
	my $config_file_contents = do {local $/; <$config_fh>; };
	
	print $outfh $header;
    # printf $outfh "Time generated  : %s \n", get_timestamp();
    # printf $outfh "Total before grep : %d (%s)\n", $total_before_grep, $freq_table;
	# printf $outfh "Total displayed   : %d \n\n", scalar @cumulative_llm_answers;
	
    my $counter = 1;
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
        my $hyperlink_ducky  = sprintf "<a href='https://duckduckgo.com/?q=!ducky+%s+%s' target='_blank'>%-50s</a>", $legalName_plus, $address_composed_string_plus, $legalName;
        printf $outfh "%-10s    %s  -> %s \n", $hyperlink_google, $hyperlink_ducky, $anno_hashref->{$legalName};
    }
    close $outfh;
}

=pod
USAGE:
    # creating a hash
        my @folder_list_1 = (
        '../ag',
        '../bl',
        );
        my %returned_hash = Mhouse::Reports::get_hash_by_legalname(\@folder_list_2);
        my $json = encode_json(\%returned_hash);
        open(my $fh, '>', 'hash_by_legalname_1.json') or die "Cannot open file: $!";
        print $fh $json;
        close $fh;

    # using a hash
        open(my $fh_in, '<', 'hash_by_legalname_1.json') or die "Cannot open file: $!";
        my $json_file_contents = do{local $/; <$fh_in>};
        my $hash_to_use = decode_json($json_file_contents);
        my $legalName = 'Sedinum Stiftung';
        print "$legalName : ";
        print Dumper $hash_to_use->{$legalName};

=cut
sub get_hash_by_legalname{
    my $folder_list_ref        = shift;
    my @folder_list = @{$folder_list_ref};
    my @data_extracted = read_mhouse_llm_scored_data(\@folder_list);
    my %returned_hash = ();
    foreach my $d (@data_extracted){
        my ($llm_answer_json_part) = ($d->{llm_answer} =~ /(\{.*\})/s);
        $llm_answer_json_part =~ s/\R/ /g;
        my $llm_answer;
        eval{$llm_answer = decode_json($llm_answer_json_part);};
        $returned_hash{$d->{legalName}} = {
            'employees' => $d->{employees},
             'personnel' => $llm_answer -> {personnel},
             'e_data'    => $llm_answer -> {e_data},
             } ;
    }
    return %returned_hash;
}



sub get_freq_table{
	my @llm_scored_arr = @_;
	my %counts;
	foreach my $rec (@llm_scored_arr) {
		$counts{ $rec->{employees} }++;
	}
	return join ", ", map { "$_ => $counts{$_}" } sort keys %counts;
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

sub report_based_on_config{
	my $config_fn = shift;
	my $config = do $config_fn;
	die "Config error: $@" if !$config;

	my $sort_logic = eval $config->{sort_logic};
	die "Sort logic error: $@" if !$sort_logic;

	my $grep_logic = eval $config->{grep_logic};
	die "Grep logic error: $@" if !$grep_logic;

	my @folder_list = @{$config->{data_folder_list}};
	my $displayed_scores_arrref = $config->{displayed_scores};
	my $annotation_folder = $config->{annotation_folder};

	my @scored_field_list = qw(personnel e_data documentation programming automation sysadmin energy_sector e_commerce logistics_supply construction agri_tech ar_vr industry_1 industry_2);
	my @cumulative_llm_answers = read_mhouse_llm_scored_data(\@folder_list, \@scored_field_list);
	printf "Total selected before grep: %d\n", scalar @cumulative_llm_answers;
	my @sorted_arr = sort { $sort_logic->($a, $b) } grep { $grep_logic->($_) } @cumulative_llm_answers;
	my $annotation_hashref = read_mhouse_annotations_from_folder($annotation_folder);
	my $out_fn = "displayed_list_" . get_timestamp() . ".html";
	my $header = get_header($config_fn, \@cumulative_llm_answers, \@sorted_arr);
	output_llm_scored_mhouse_json_annotated(\@sorted_arr, $out_fn, $annotation_hashref, $displayed_scores_arrref, $config_fn, $header);
}


1;
