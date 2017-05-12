
[% VARIABLE %]

<!-- BEGIN OUTER_LOOP -->

	[% VARIABLE %]

	<!-- BEGIN OUTER_YES -->
	OUTER_YES
	<!-- END OUTER_YES -->
	
	<!-- BEGIN OUTER_NO -->
	OUTER_NO
	<!-- END OUTER_NO -->

	<!-- BEGIN VAR.INNER_LOOP -->
  
  		[% VARIABLE %]
  
		<!-- BEGIN INNER_YES -->
		INNER_YES
		<!-- END INNER_YES -->
		
		<!-- BEGIN INNER_NO -->
		INNER_NO
		<!-- END INNER_NO -->
  
	<!-- END VAR.INNER_LOOP -->

<!-- END OUTER_LOOP -->

[% VARIABLE %]