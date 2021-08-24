# NAME

Google::RestApi - API to Google Drive API V3 and Sheets API V4.

# SYNOPSIS

>     # create a new RestApi object to be used by Drive and Sheets
>     use Google::RestApi;
>     $rest_api = Google::RestApi->new(
>       config_file   => <path_to_config_file>,
>       auth          => <object|hashref>,
>       timeout       => <int>,
>       throttle      => <int>,
>       api_callback  => <coderef>,
>     );
>
>     # you can call the raw api directly, but usually Drive and Sheets will take care of forming the correct API calls for you.
>     $response = $rest_api->api(
>       uri     => <google_api_url>,
>       method  => get|head|put|patch|post|delete,
>       headers => [],
>       params  => <query_params>,
>       content => <data_for_body>,
>     );
>
>     use Google::RestApi::DriveApi3;
>     $drive = Google::RestApi::DriveApi3->new(api => $rest_api);
>     $file = $drive->file(id => 'xxxx');
>     $copy = $file->copy(title => 'my-copy-of-xxx');
>
>     use Google::RestApi::SheetsApi4;
>     $sheets_api = Google::RestApi::SheetsApi4->new(api => $rest_api);
>     $sheet = $sheets_api->open_spreadsheet(title => "payroll");
>     $ws0 = $sheet->open_worksheet(id => 0);
>
>     # sub Worksheet::cell/col/cols/row/rows immediately get/set
>     # values. this is less efficient but the simplest way to
>     # interface with the api. you don't deal with any intermediate
>     # api objects.
>     
>     # add some data to the worksheet:
>     @values = (
>       [ 1001, "Herb Ellis", "100", "10000" ],
>       [ 1002, "Bela Fleck", "200", "20000" ],
>       [ 1003, "Freddie Mercury", "999", "99999" ],
>     );
>     $ws0->rows([1, 2, 3], \@values);
>     $values = $ws0->rows([1, 2, 3]);
>
>     # use and manipulate 'range' objects to do more complex work.
>     # ranges can be specified in many ways, use whatever way is most convenient.
>     $range = $ws0->range("A1:B2");
>     $range = $ws0->range([[1,1],[2,2]]);
>     $range = $ws0->range([{col => 1, row => 1}, {col => 2, row => 2}]);
>
>     $cell = $ws0->range_cell("A1");
>     $cell = $ws0->range_cell([1,1]);
>     $cell = $ws0->range_cell({col => 1, row => 1});
>
>     $col = $ws0->range_col(1);
>     $col = $ws0->range_col("A3:A");
>     $col = $ws0->range_col([1]);
>     $col = $ws0->range_col([[1, 3], [1]]);
>     $col = $ws0->range_col({col => 1});
>
>     $row = $ws0->range_row(1);
>     $row = $ws0->range_row("C1:1");
>     $row = $ws0->range_row([<falsey>, 1]);
>     $row = $ws0->range_row({row => 1});
>     $row = $ws0->range_row([col => 3, row => 1 }, {row => 1}]);
>
>     # add a header:
>     $row = $ws0->range_row(1);
>     $row->insert_d()->freeze()->bold()->italic()->center()->middle()->submit_requests();
>     # sub 'values' sends the values to the api directly, not using batch (less efficient):
>     $row->values(values => [qw(Id Name Tax Salary)]);
>
>     # bold the names:
>     $col = $ws0->range_col("B2:B");
>     $col->bold()->submit_requests();
>
>     # add some tax info:
>     $tax = $ws0->range_cell([ 3, 5 ]);   # or 'C5' or [ 'C', 5 ] or { col => 3, row => 5 }...
>     $salary = $ws0->range_cell({ col => "D", row => 5 }); # same as "D5"
>     # set up batch update with staged values:
>     $tax->batch_values(values => "=SUM(C2:C4)");
>     $salary->batch_values(values => "=SUM(D2:D4)");
>     # now collect the ranges into a group and send the values via batch:
>     $rg = $sheet->range_group($tax, $salary);
>     # now actually send the values to the spreadsheet:
>     $rg->submit_values();
> 
>     # bold and italicize both cells, and put a solid border around each one, and send the formats to the spreadsheet:
>     $rg->bold()->italic()->bd_solid()->submit_requests();
>

# DESCRIPTION

Google::RestApi is a framework for interfacing with Google products, currently Drive and Sheets.

The biggest hurdle to using this library is actually setting up the authorization to access your Drive and Sheets account via a script.
The Google development web space is huge and complex. All that's required here is an OAuth2 token to authorize your script that uses this
library to access your Drive and Sheets. See bin/google_restapi_oauth_token_creator for instructions on how to do so. Once you've done it
a couple of times it's straight forward.

The synopsis above is a quick reference. For more detailed information, most of the good stuff is in the following pods:

    Google::RestApi
    Google::RestApi::DriveApi3
    Google::RestApi::SheetsApi4
    Google::RestApi::SheetsApi4::Spreadsheet
    Google::RestApi::SheetsApi4::Worksheet
    Google::RestApi::SheetsApi4::Range

Once you have successfully created your OAuth2 token, you can run the integration tests to ensure everything is working correctly.
Set the environment variable GOOGLE_RESTAPI_CONFIG = to the path to your auth config file for the integration scripts to run.
See t/run_integration for further instructions.

t/tutorial/Sheets also has a step-by-step tutorial of creating and updating a spreadsheet, showing you the API calls and return values for each step. This will help you understand how the API interacts with Google.

# STATUS

This api is currently very much in beta status. It is incomplete.
There may be design flaws that need to be addressed in later
releases. Later releases may break this release. Not all api
calls have been implemented. Tests are not comprehensive.

But it gets the job done.

This is a work in progress, released at this stage in order to
assist others, and in the hopes that others will contribute to
its completeness.

# AUTHORS

- Robin Murray mvsjes@cpan.org

# COPYRIGHT

Copyright (c) 2021, Robin Murray. All rights reserved.

This program is free software; you may redistribute it and/or modify it under the same terms as Perl itself.
