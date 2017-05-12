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

public class PipelineSentence extends PipelineItem {
	private String                  sentence;
	private PipelineTokenList       tokens;
	private PipelineDependencyList  dependencies;
	private PipelineCoreferenceList coreferences;

	public String                  getSentence()     { return sentence; }
	public PipelineTokenList       getTokens()       { return tokens; }
	public PipelineDependencyList  getDependencies() { return dependencies; }
	public PipelineCoreferenceList getCoreferences() { return coreferences; }

	public PipelineSentence() {
		sentence     = "";
		tokens       = new PipelineTokenList();
		dependencies = new PipelineDependencyList();
		coreferences = new PipelineCoreferenceList();
	}

	public PipelineSentence(
		String                 sentence,
		PipelineTokenList      tokens,
		PipelineDependencyList dependencies
	) {
		this.sentence     = sentence;
		this.tokens       = tokens;
		this.dependencies = dependencies;
		this.coreferences = new PipelineCoreferenceList();
	}

	public void addCoreference(PipelineCoreference cr) {
		coreferences.add(cr);
	}

	public String toCompactString() { return join("\n"); }

	@Override public String toString() {
		return join("\n\n");
	}

	public String join(String sep) {
		return sentence + sep + tokens.toString() + sep + dependencies.toString() + sep
					+ coreferences.toString();
	}
}
