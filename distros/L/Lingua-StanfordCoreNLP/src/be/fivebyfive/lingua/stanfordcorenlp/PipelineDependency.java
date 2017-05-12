/*
 * Lingua::StanfordCoreNLP
 * Copyright © 2011-2013 Kalle Räisänen.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 * 
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see L<http://www.gnu.org/licenses/>.
 */
package be.fivebyfive.lingua.stanfordcorenlp;

import edu.stanford.nlp.trees.GrammaticalRelation;

public class PipelineDependency extends PipelineItem {
	private PipelineToken governor;
	private PipelineToken dependent;
	private int           govIndex;
	private int           depIndex;
	private String        relation;
	private String        longRelation;

	public PipelineToken getGovernor()  { return governor;  }
	public PipelineToken getDependent() { return dependent; }
	public int getGovernorIndex()       { return govIndex; }
	public int getDependentIndex()      { return depIndex; }
	public String getRelation()         { return relation; }
	public String getLongRelation()     { return longRelation; }

	public PipelineDependency(
		PipelineToken governor,
		PipelineToken dependent,
		int           govIndex,
		int           depIndex,
		GrammaticalRelation relation
	) {
		this.governor     = governor;
		this.dependent    = dependent;
		this.govIndex     = govIndex;
		this.depIndex     = depIndex;
		this.relation     = relation.toString();
		this.longRelation = relation.getLongName();
	}

	public String toCompactString() { return toCompactString(false); }

	public String toCompactString(boolean includeIndices) {
		return relation + "("
		     + governor.getWord()  + (includeIndices ? "-" + govIndex : "")
		     + ", "
		     + dependent.getWord() + (includeIndices ? "-" + depIndex : "")
		     + ")";
	}

	public String toString(boolean includeIndices) {
		return toCompactString(includeIndices) + " [" + longRelation + "]";
	}

	@Override public String toString() {
		return toString(true);
	}
}