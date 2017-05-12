
[% VARIABLE %]

<!-- LOOP OUTER_LOOP -->

	[% VARIABLE %]

	<!-- LOOP OUTER_NO_1 -->
	OUTER_NO
	<!-- END OUTER_NO_1 -->
	
	<!-- LOOP OUTER_NO_2 -->
	OUTER_NO
	<!-- END OUTER_NO_2 -->

	<!-- LOOP VAR.INNER_LOOP -->
  
  		[% VARIABLE %]
  
		<!-- LOOP INNER_NO_1 -->
		INNER_YES
		<!-- END INNER_NO_1 -->
		
		<!-- LOOP INNER_NO_2 -->
		INNER_NO
		<!-- END INNER_NO_2 -->
  
	<!-- END VAR.INNER_LOOP -->

<!-- END OUTER_LOOP -->

[% VARIABLE %]