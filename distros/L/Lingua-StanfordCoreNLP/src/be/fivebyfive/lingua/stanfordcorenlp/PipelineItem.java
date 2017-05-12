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

import java.util.UUID;

public abstract class PipelineItem {
    protected UUID   id    = null;
    protected String idStr = "";
    protected static long idLeast = Long.MIN_VALUE;
    protected static long idMost  = Long.MIN_VALUE;

    public void setIDFromString(String str) {
        id = UUID.nameUUIDFromBytes(str.getBytes());
    }

    public static void initializeCounters(long least, long most) {
        idLeast = least;
        idMost  = most;
    }

    public static void randomizeCounters() {
        UUID t = UUID.randomUUID();

        PipelineItem.initializeCounters(
            t.getLeastSignificantBits(),
            t.getMostSignificantBits()
        );
    }

    public static UUID generateID() {
        if (idLeast <= Long.MAX_VALUE) {
            idLeast++;
        } else if (idMost <= Long.MAX_VALUE) {
            idMost++;
        } else { // if this happens, you've got big problems
            System.out.println("PipelineItem.generateID(): ran out of IDs!");
        }

        return new UUID(idMost, idLeast);
    }

    public UUID getID() {
        if (id == null) {
            id = PipelineItem.generateID();
        }
        return id;
    }

    public String getIDString() {
        if (idStr.equals("")) {
            idStr = getID().toString();
        }
        return idStr;
    }

    public boolean identicalTo(PipelineItem b) {
        return getID().equals(b.getID());
    }

    abstract public String toCompactString();
}
