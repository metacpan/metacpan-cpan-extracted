<table>
    <tr>
        <th colspan="2">[% this.get_namespace %] - [% this.get_service %]::[% this.get_usecase %]</th>
    </tr>[% FOREACH step = data.step_data -%][% IF step.value.control; -%]
    <%COMMENT%>controls for step [% step.key %]<%/COMMENT%>[% FOREACH control = step.value.control %]
    <tr>
        <td>[% control %]</td>
        <td>
            <%= [% control %].get_html %>
            <%WITH [% control %].get_validator_control %><%= get_html %><%/WITH%>
        </td>
    </tr>[% END; END; END%]    
    <tr>
        <td colspan="2">powered by Perl and the Hyper Framework</td>
    </tr>
</table>
