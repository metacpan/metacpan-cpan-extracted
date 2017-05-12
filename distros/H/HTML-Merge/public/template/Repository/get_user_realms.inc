<$REM - Assign Default zero Realm to var >
<$RSET.user_realms=' "0" '>

<$REM - Get The User Group realms >
<$R[user_realms].DB='SYSTEM'>
<$R[user_realms].Q='SELECT DISTINCT b.realm_id realm_id
					FROM user_group_matrix a
					INNER JOIN group_realm_matrix b ON b.group_id=a.group_id
					INNER JOIN users_t c ON c.id=a.user_id
					WHERE c.username="<$RUSER>"'>

<$R[user_realms].LOOP>
	<$RSET.user_realms=' "<$RVAR.user_realms>,<$R[user_realms].SQL.realm_id>" '>
</$R[user_realms].LOOP>

<$REM - Get The User extra realms >
<$R[user_realms].Q='SELECT DISTINCT a.realm_id realm_id
					FROM user_realm_matrix a
					INNER JOIN users_t b ON b.id=a.user_id
					WHERE b.username="<$RUSER>" '>

<$R[user_realms].LOOP>
	<$RSET.user_realms=' "<$RVAR.user_realms>,<$R[user_realms].SQL.realm_id>" '>
</$R[user_realms].LOOP>
<$RDB='DEFAULT'>
